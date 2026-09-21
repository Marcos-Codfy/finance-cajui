import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/money/money.dart';
import 'package:meta/meta.dart';

/// O pagamento de uma fatura: uma **liquidação**, não um lançamento (RN-340).
///
/// Não entra em bloco nenhum e não muda indicador de despesa: cada compra já
/// contou quando foi feita. Pagar R$ 1.240,00 em 05/10 não acrescenta
/// R$ 1.240,00 às despesas de outubro.
@immutable
final class Settlement {
  /// Registra o pagamento de [amount] da fatura de [dueMonth] do cartão
  /// [cardId].
  const new({
    required this.id,
    required this.cardId,
    required this.dueMonth,
    required this.amount,
    required this.paidOn,
  });

  /// O identificador da liquidação.
  final String id;

  /// O cartão cuja fatura foi paga.
  final String cardId;

  /// O mês de vencimento da fatura paga: é o que a identifica.
  final BudgetMonth dueMonth;

  /// Quanto foi pago.
  final Money amount;

  /// Quando foi pago.
  final LocalDate paidOn;

  /// O que ficou **em aberto** depois deste pagamento, para uma fatura de
  /// [statementTotal]. Maior que zero, vira dívida — rotativo ou parcelamento
  /// de fatura, conforme o que foi combinado com o banco (RN-342).
  Money openBalanceFor(Money statementTotal) =>
      (statementTotal - amount).orZeroIfNegative;

  /// O que foi pago **a mais** que o calculado (RN-344). É aceito, com aviso,
  /// e a diferença alimenta a busca por lançamento que falta (RN-332).
  Money overpaidFor(Money statementTotal) =>
      (amount - statementTotal).orZeroIfNegative;
}
