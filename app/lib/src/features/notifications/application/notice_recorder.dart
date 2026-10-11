import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/draft_defaults.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/notifications/application/notice_announcement.dart';
import 'package:cajui/src/features/notifications/application/notice_payment_method.dart';
import 'package:cajui/src/features/notifications/application/notice_words.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Decide o que fazer com a movimentação que o banco avisou, e faz: lança
/// sozinho, pede um toque ou deixa quieto (RN-786 a RN-789).
class NoticeRecorder {
  /// Cria o caso de uso sobre os providers de [ref].
  const new(this.ref);

  /// De onde saem o livro, o relógio e o classificador.
  final Ref ref;

  /// Quanto a categoria espera pela IA do servidor. Em segundo plano o
  /// Android não espera para sempre, e o app aberto espera a leitura
  /// terminar: depois disso, valem as regras do aparelho (RN-752).
  static const classifierTimeout = Duration(seconds: 12);

  /// A chave do lançamento nascido da notificação [noticeId]. É a mesma a
  /// cada repetição da notificação: lançar de novo não grava outro fato
  /// (RN-781, RN-789).
  static String entryIdOf(String noticeId) => 'notice-$noticeId';

  /// O que avisar depois de tratar [reading], vinda da notificação
  /// [noticeId]; `null` quando não há o que avisar.
  Future<NoticeAnnouncement?> handle(
    String noticeId,
    BankReading reading,
  ) async {
    if (reading.kind.isIncoming) return NoticeWords.income(noticeId, reading);
    final book = await ref.read(ledgerProvider.future);
    final id = entryIdOf(noticeId);
    if (_known(book, id) || _alreadyThere(book, reading)) return null;
    final method = NoticePaymentMethod.of(reading, book);
    if (method == null || reading.isInstallment || _cardBill(reading, book)) {
      return _ask(noticeId, reading);
    }
    return await _record(id, reading, book, method);
  }

  /// Pix, transferência ou boleto para o banco de um cartão cadastrado é,
  /// quase sempre, a fatura sendo paga de outro banco ("Pix de R$ 1.234,56
  /// para NU PAGAMENTOS"). A fatura não é despesa (RN-1001): as compras
  /// já contaram. Lançar sozinho contaria o mês em dobro; pede um toque, e
  /// a conferência oferece "é pagamento de fatura".
  static bool _cardBill(BankReading reading, LedgerBook book) {
    final payee = reading.counterpart;
    if (payee == null || !_paysSomeone.contains(reading.kind)) return false;
    return book.cards.any(
      (card) => BankApp.values.any(
        (bank) => bank.namesCard(card.name) && bank.namesCard(payee),
      ),
    );
  }

  static const Set<MovementKind> _paysSomeone = {
    MovementKind.pixSent,
    MovementKind.transferSent,
    MovementKind.boletoPaid,
  };

  /// Já lançado, ou lançado e desfeito: desfazer é a palavra final.
  static bool _known(LedgerBook book, String id) =>
      book.entryOf(id) != null || book.cancelledIds.contains(id);

  /// O mesmo valor no mesmo dia já está no livro: o comprovante foi
  /// compartilhado também, ou a carteira e o banco avisaram a mesma compra.
  static bool _alreadyThere(LedgerBook book, BankReading reading) =>
      PossibleDuplicate.near(
        book.entries,
        amount: reading.amount,
        occurredOn: reading.occurredOn,
        days: 0,
      ) !=
      null;

  /// A carteira não diz o banco do cartão: quando nem os dígitos o
  /// identificam, quem lança é a notificação do próprio banco, que chega
  /// junto. Pedir um toque aqui seria um aviso a mais para cada compra.
  static NoticeAnnouncement? _ask(String noticeId, BankReading reading) =>
      reading.app.isWallet && !reading.isInstallment
      ? null
      : NoticeWords.purchase(noticeId, reading);

  Future<NoticeAnnouncement?> _record(
    String id,
    BankReading reading,
    LedgerBook book,
    PaymentMethod method,
  ) async {
    final category = await _categoryOf(reading, book);
    final result = Entry.create(
      id: id,
      origin: EntryOrigin.notification,
      description:
          MerchantName.pretty(reading.counterpart) ?? reading.kind.label,
      amount: reading.amount,
      occurredOn: reading.occurredOn,
      category: category,
      paymentLines: [method.line(reading.amount)],
      today: ref.read(clockProvider).today(),
    );
    final entry = result.valueOrNull;
    if (entry == null) return null;
    await ref.read(ledgerProvider.notifier).append(EntryRecorded(entry));
    return NoticeWords.recorded(
      entry,
      kind: reading.kind,
      category: category.name,
      method: method.name,
    );
  }

  /// A categoria pelo mesmo classificador da captura, com as regras que a
  /// pessoa já ensinou. Sem palpite, Outros — e a revisão de domingo traz o
  /// lançamento de volta (RN-870).
  Future<Category> _categoryOf(BankReading reading, LedgerBook book) async {
    final fallback = book.categoryOf(DraftDefaults.fallbackCategoryId);
    if (reading.counterpart == null) return fallback;
    final request = ClassificationRequest(
      text: ReceiptText.clean(NoticeWords.receiptText(reading)),
      categories: book.categories,
      today: ref.read(clockProvider).today(),
      learnedRules: await ref.read(captureShelfProvider).learnedRules(),
      categoryByMerchantKind: DefaultCatalog.categoryByMerchantKind,
    );
    final proposal = await _classify(request);
    final id =
        proposal.category.value ?? proposal.category.candidates.firstOrNull;
    return book.categories.where((it) => it.id == id).firstOrNull ?? fallback;
  }

  Future<EntryProposal> _classify(ClassificationRequest request) async {
    const rules = RuleBasedClassifier();
    try {
      return await ref
          .read(receiptClassifierProvider)
          .classify(request)
          .timeout(classifierTimeout, onTimeout: () => rules.classify(request));
    } on Exception {
      return await rules.classify(request);
    }
  }
}
