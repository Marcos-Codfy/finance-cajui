import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/receipts/application/capture.dart';
import 'package:cajui/src/features/receipts/application/capture_outcome.dart';
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
      case SharedFile(:final id, :final path):
        final read = await ref
            .read(receiptReaderProvider)
            .read(item, onPage: onPage);
        return switch (read) {
          ReadFailed(:final code) => CaptureRefused(code),
          ReadText(:final text) => await _propose(
            PendingCapture(
              id: id,
              receivedOn: today,
              text: text,
              filePath: path,
            ),
          ),
        };
    }
  }

  /// Monta de novo a proposta de uma captura guardada, já com o que o app
  /// aprendeu desde então.
  Future<Capture> reopen(PendingCapture pending) => _classify(pending);

  Future<CaptureOutcome> _propose(PendingCapture raw) async {
    final clean = PendingCapture(
      id: raw.id,
      receivedOn: raw.receivedOn,
      // O texto lido é dado não confiável: tamanho limitado e caracteres
      // invisíveis fora antes de qualquer regra olhar para ele.
      text: ReceiptText.clean(raw.text),
      filePath: raw.filePath,
    );
    final unreadable = clean.text.trim().isEmpty;
    if (unreadable) return const CaptureRefused(ErrorCode.capt01);
    return CaptureProposed(await _classify(clean));
  }

  Future<Capture> _classify(PendingCapture source) async {
    final book = await ref.read(ledgerProvider.future);
    final proposal = await ref
        .read(receiptClassifierProvider)
        .classify(
          ClassificationRequest(
            text: source.text,
            categories: book.categories,
            today: ref.read(clockProvider).today(),
            learnedRules: await ref.read(captureShelfProvider).learnedRules(),
          ),
        );
    return Capture(source: source, proposal: proposal);
  }

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
    }
    await shelf.close(capture.source.id);
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
