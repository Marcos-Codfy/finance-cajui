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

  /// A rota de [proposal]. Tipo em dúvida é compra: na dúvida, a conferência
  /// mostra tudo e a pessoa decide.
  static CaptureRoute of(EntryProposal proposal) {
    if (proposal.isStatement) return CaptureRoute.statement;
    return switch (proposal.documentKind.value) {
      DocumentKind.incomeReceipt => CaptureRoute.income,
      DocumentKind.statementPayment ||
      DocumentKind.ownTransfer => CaptureRoute.notAnExpense,
      _ => CaptureRoute.expense,
    };
  }
}
