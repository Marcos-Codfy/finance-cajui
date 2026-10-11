import 'package:domain/src/debts/debt_kind.dart';

/// Os três tipos de dívida da planilha do dono. Dívida é só o que atravessa
/// mais de um mês; compra no cartão paga inteira na fatura seguinte é gasto
/// do mês, e não aparece aqui.
enum DebtType {
  /// Parcelamento, carnê, empréstimo, financiamento.
  installments,

  /// Conta atrasada.
  overdue,

  /// Rotativo do cartão: o que sobrou da fatura paga em parte.
  revolving;

  /// O tipo de [kind]. Os nomes guardados nos eventos continuam os de
  /// sempre; o tipo é só a forma de ler.
  static DebtType of(DebtKind kind) => switch (kind) {
    DebtKind.cardRevolving => DebtType.revolving,
    DebtKind.overdueBill => DebtType.overdue,
    DebtKind.loan ||
    DebtKind.financing ||
    DebtKind.cardInstallment ||
    DebtKind.informal => DebtType.installments,
  };
}
