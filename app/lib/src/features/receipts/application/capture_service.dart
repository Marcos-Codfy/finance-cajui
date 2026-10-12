import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/ledger/application/answer_memory.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/receipts/application/capture.dart';
import 'package:cajui/src/features/receipts/application/capture_outcome.dart';
import 'package:cajui/src/features/receipts/application/classification_memory.dart';
import 'package:cajui/src/features/receipts/application/pending_capture.dart';
import 'package:cajui/src/features/receipts/application/read_outcome.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:cajui/src/features/receipts/application/shared_item.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Os casos de uso da captura: abrir o que chegou, guardar para depois,
/// descartar e aprender com a correção.
///
/// A captura inteira roda no aparelho (RN-780): leitura, limpeza do texto e
/// classificação por regras. O app nunca espera a rede para deixar lançar.
class CaptureService {
  /// Cria o serviço sobre os providers de [ref].
  const new(this.ref);

  /// De onde saem as portas e o livro.
  final Ref ref;

  /// Lê e classifica [item]. [onPage] recebe o progresso real de um PDF.
  Future<CaptureOutcome> open(
    SharedItem item, {
    void Function(int page, int of)? onPage,
  }) async {
    final today = ref.read(clockProvider).today();
    switch (item) {
      case RejectedShare(:final code, :final detail):
        return CaptureRefused(code, detail: detail);
      case SharedText(:final id, :final text):
        return await _propose(
          PendingCapture(id: id, receivedOn: today, text: text),
        );
      case SharedFile():
        return await _openFile(item, today, onPage);
    }
  }

  Future<CaptureOutcome> _openFile(
    SharedFile file,
    LocalDate today,
    void Function(int page, int of)? onPage,
  ) async {
    final read = await ref
        .read(receiptReaderProvider)
        .read(file, onPage: onPage);
    return switch (read) {
      ReadFailed(:final code) => CaptureRefused(code),
      final ReadText text => await _propose(
        PendingCapture(
          id: file.id,
          receivedOn: today,
          text: _statementText(text) ?? text.text,
          filePath: file.path,
          isPdf: file.isPdf,
          images: text.images,
        ),
      ),
    };
  }

  /// O texto em linhas, quando ele tem cara de extrato: o reconhecimento
  /// (RN-1100) olha linhas com data e valor, e o texto por blocos do OCR
  /// pode separá-los numa página em forma de tabela. Guardado como o texto
  /// da captura, ele também é o que a reabertura reconhece depois.
  static String? _statementText(ReadText read) {
    final rows = read.rowsText;
    return rows != null && StatementShape.looksLike(rows) ? rows : null;
  }

  /// Monta de novo a proposta de uma captura guardada, já com o que o app
  /// aprendeu desde então.
  ///
  /// O arquivo fica no aparelho até ser descartado: lido de novo, devolve as
  /// imagens, e a IA vê o mesmo que viu da primeira vez — o servidor responde
  /// do cache, sem pagar de novo. Sem isso, a foto que só a IA conseguiu ler
  /// voltava em branco.
  Future<Capture> reopen(PendingCapture pending) async {
    if (StatementShape.looksLike(pending.text)) return statementOf(pending);
    final path = pending.filePath;
    if (path == null) return await _classify(pending);
    final read = await ref
        .read(receiptReaderProvider)
        .read(SharedFile(id: pending.id, path: path, isPdf: pending.isPdf));
    return await _classify(
      pending.withImages(read is ReadText ? read.images : const []),
    );
  }

  Future<CaptureOutcome> _propose(PendingCapture raw) async {
    final clean = PendingCapture(
      id: raw.id,
      receivedOn: raw.receivedOn,
      // O texto lido é dado não confiável: tamanho limitado e caracteres
      // invisíveis fora antes de qualquer regra olhar para ele.
      text: ReceiptText.clean(raw.text),
      filePath: raw.filePath,
      isPdf: raw.isPdf,
      images: raw.images,
    );
    final unreadable = _unreadable(clean);
    if (unreadable && clean.images.isEmpty) {
      return const CaptureRefused(ErrorCode.capt01);
    }
    if (StatementShape.looksLike(clean.text)) {
      return CaptureProposed(statementOf(clean));
    }
    final capture = await _classify(clean);
    // O celular não leu, e a IA também não achou valor: aí não há o que
    // conferir, e a saída é a mesma de sempre — outra foto, ou digitar.
    if (unreadable && capture.proposal.amount.confidence == Confidence.low) {
      return const CaptureRefused(ErrorCode.capt01);
    }
    return CaptureProposed(capture);
  }

  /// A captura de um extrato reconhecido no celular (RN-1100): não passa
  /// pela leitura de comprovante, que o cortaria em 8.000 caracteres e o
  /// mandaria à IA sem a máscara da ADR-030. Vai inteiro para a conversa
  /// com a Juju, que o lê página a página.
  static Capture statementOf(PendingCapture source) => Capture(
    source: source,
    proposal: const EntryProposal(
      documentKind: ProposedField.resolved(
        DocumentKind.statement,
        source: FieldSource.fixedRule,
      ),
      amount: ProposedField.unread(),
      occurredOn: ProposedField.unread(),
      category: ProposedField.unread(),
      paymentKind: ProposedField.unread(),
    ),
  );

  /// Menos que isso, lido de uma foto, não é comprovante: é ruído de foto
  /// escura.
  static const minReadableChars = 8;

  /// Texto compartilhado é outra coisa: "R$ 9,90" é curto, e é tudo.
  static bool _unreadable(PendingCapture capture) {
    final length = capture.text.trim().length;
    return capture.filePath == null ? length == 0 : length < minReadableChars;
  }

  Future<Capture> _classify(PendingCapture source) async {
    final book = await ref.read(ledgerProvider.future);
    final rules = await ClassificationMemory.of(
      book,
      ref.read(captureShelfProvider),
    );
    final proposal = await ref
        .read(receiptClassifierProvider)
        .classify(
          ClassificationRequest(
            text: source.text,
            categories: book.categories,
            today: ref.read(clockProvider).today(),
            learnedRules: rules.shared,
            personalRules: rules.personal,
            categoryByMerchantKind: DefaultCatalog.categoryByMerchantKind,
            images: source.images,
          ),
        );
    return Capture(source: source, proposal: proposal);
  }

  /// Abre a câmera do aparelho para fotografar um comprovante de papel
  /// (ADR-017). A foto entra na mesma fila do compartilhamento: quem avisa
  /// que ela chegou é a caixa de entrada, e a conferência abre igual.
  ///
  /// Devolve `false` quando o aparelho não tem com que fotografar.
  Future<bool> photograph() => ref.read(receiptInboxProvider).takePhoto();

  /// Se dá para fotografar neste aparelho.
  bool get canPhotograph => ref.read(receiptInboxProvider).canPhotograph;

  /// Abre o seletor do aparelho: foto da galeria, print, PDF de extrato. O
  /// que for escolhido entra na mesma fila do compartilhamento.
  Future<bool> pickFromDevice() => ref.read(receiptInboxProvider).pickFiles();

  /// Se dá para escolher arquivos neste aparelho.
  bool get canPickFiles => ref.read(receiptInboxProvider).canPickFiles;

  /// "Conferir depois": a captura fica guardada, fora de qualquer indicador.
  Future<void> defer(Capture capture) async {
    await ref.read(captureShelfProvider).defer(capture.source);
    ref.invalidate(pendingCapturesProvider);
  }

  /// Fecha a captura que virou lançamento e, se a pessoa escolheu uma
  /// categoria que o app não tinha proposto com certeza, aprende (RN-763).
  Future<void> confirmed(Capture capture, Entry entry) async {
    final shelf = ref.read(captureShelfProvider);
    final merchant = capture.proposal.merchant;
    final alreadySure = capture.proposal.category.value == entry.categoryId;
    if (merchant != null && !alreadySure) {
      await shelf.learn(merchant: merchant, categoryId: entry.categoryId);
      await _remember(merchant, entry.categoryId);
    }
    await shelf.close(capture.source.id);
    ref.invalidate(pendingCapturesProvider);
  }

  /// A mesma regra, como resposta lembrada: chega ao outro celular e vale
  /// também no extrato (RN-1116). Pix para alguém fica marcado como de
  /// pessoa, e nunca vira exemplo para a IA (RN-1107). A regra antiga
  /// continua sendo gravada: é ela que vale enquanto a memória não chegou.
  Future<void> _remember(String merchant, String categoryId) async {
    final key = PossibleDuplicate.normalize(merchant);
    await ref
        .read(answerMemoryProvider)
        .remember(
          key: key,
          categoryId: categoryId,
          aboutPerson: LearnedRules.looksLikePerson(key),
        );
  }

  /// Fecha a captura sem aprender nada: ela virou entrada, pagamento de
  /// fatura ou as linhas de um extrato.
  Future<void> close(Capture capture) async {
    await ref.read(captureShelfProvider).close(capture.source.id);
    ref.invalidate(pendingCapturesProvider);
  }

  /// Descarta: apaga o arquivo local e não grava nada (RN-723).
  Future<void> discard(Capture capture) async {
    final path = capture.source.filePath;
    if (path != null) {
      await ref
          .read(receiptInboxProvider)
          .discard(SharedFile(id: capture.source.id, path: path, isPdf: false));
    }
    await ref.read(captureShelfProvider).close(capture.source.id);
    ref.invalidate(pendingCapturesProvider);
  }
}
