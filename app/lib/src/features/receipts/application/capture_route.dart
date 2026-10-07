import 'package:domain/domain.dart';

/// Para onde um comprovante lido vai: a tela que sabe tratar o que ele é.
///
/// Nem todo documento é uma compra (RN-756 a RN-759, RN-707). O extrato vira
/// uma lista para marcar; o Pix recebido vira entrada; o pagamento de fatura
/// e a transferência entre contas suas não viram nada — e a pessoa pode
/// sempre dizer "é uma despesa", se a leitura errou.
enum CaptureRoute {
  /// Uma compra: a conferência do lançamento, como sempre.
  expense,

  /// Um extrato: a lista de movimentações para marcar.
  statement,

  /// Dinheiro que entrou: vira recebimento.
  income,

  /// Pagamento de fatura ou transferência entre contas próprias.
  notAnExpense;

  /// A rota de [proposal]. O tipo em dúvida que pode não ser compra — a
  /// fatura que só a IA viu (RN-757) — vai para a tela dele, que pergunta e
  /// tem "É uma despesa": a conferência de despesa, pronta para um toque,
  /// lançaria o pagamento da fatura como gasto.
  static CaptureRoute of(EntryProposal proposal) {
    if (proposal.isStatement) return CaptureRoute.statement;
    return switch (kindOf(proposal)) {
      DocumentKind.incomeReceipt => CaptureRoute.income,
      DocumentKind.statementPayment ||
      DocumentKind.ownTransfer => CaptureRoute.notAnExpense,
      _ => CaptureRoute.expense,
    };
  }

  /// O tipo que decide a tela: o lido, ou, na dúvida, o primeiro candidato
  /// que não é compra.
  static DocumentKind? kindOf(EntryProposal proposal) {
    final kind = proposal.documentKind;
    return kind.value ??
        kind.candidates
            .where((candidate) => candidate != DocumentKind.purchase)
            .firstOrNull;
  }
}
