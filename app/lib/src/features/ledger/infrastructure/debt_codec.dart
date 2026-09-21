import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:domain/domain.dart';

/// A ida e a volta das dívidas com o registro.
///
/// Da dívida se guarda o que a pessoa informou — credor, parcela, quantas são
/// e quantas já foram — e, se houver, o valor para quitar que o credor disse
/// (RN-511). **Número de contrato nunca existe no Cajui.**
abstract final class DebtCodec {
  /// O que gravar para [debt].
  static Map<String, Object?> encodeDebt(Debt debt) => {
    'id': debt.id,
    'creditor': debt.creditor,
    'kind': debt.kind.name,
    'installmentCents': debt.installmentAmount.cents,
    'totalInstallments': debt.totalInstallments,
    'paidInstallments': debt.paidInstallments,
    'dueDay': debt.dueDay,
    'firstMonth': '${debt.firstMonth}',
    'cardId': debt.cardId,
    'payoffCents': debt.payoffQuote?.amount.cents,
    'payoffQuotedOn': debt.payoffQuote == null
        ? null
        : '${debt.payoffQuote!.quotedOn}',
  };

  /// A dívida gravada em [payload]. Já foi aceita pelo domínio quando foi
  /// gravada.
  static Debt decodeDebt(Map<String, Object?> payload) {
    final debt = Debt.create(
      id: payload['id']! as String,
      creditor: payload['creditor']! as String,
      kind: EntryCodec.named(DebtKind.values, payload['kind']! as String),
      installmentAmount: Money.fromCents(payload['installmentCents']! as int),
      totalInstallments: payload['totalInstallments']! as int,
      paidInstallments: payload['paidInstallments']! as int,
      dueDay: payload['dueDay']! as int,
      firstMonth: _month(payload['firstMonth']! as String),
      cardId: payload['cardId'] as String?,
    ).valueOrNull!;
    final payoff = payload['payoffCents'] as int?;
    if (payoff == null) return debt;
    return debt.withPayoffQuote(
      PayoffQuote(
        amount: Money.fromCents(payoff),
        quotedOn: EntryCodec.parseDate(payload['payoffQuotedOn']! as String),
      ),
    );
  }

  static BudgetMonth _month(String text) {
    final [year, month] = text.split('-').map(int.parse).toList();
    return BudgetMonth(year, month);
  }

  /// O que gravar para o pagamento de parcela [event].
  static Map<String, Object?> encodePayment(DebtInstallmentPaid event) => {
    'debtId': event.debtId,
    'entryId': event.entryId,
  };

  /// O pagamento de parcela gravado em [payload].
  static DebtInstallmentPaid decodePayment(Map<String, Object?> payload) {
    return DebtInstallmentPaid(
      debtId: payload['debtId']! as String,
      entryId: payload['entryId']! as String,
    );
  }
}
