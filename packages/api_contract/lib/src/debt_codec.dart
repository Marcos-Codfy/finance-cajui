import 'package:api_contract/src/entry_codec.dart';
import 'package:domain/domain.dart';

/// A ligação entre um lançamento e a dívida cuja parcela ele pagou.
typedef DebtPayment = ({String debtId, String entryId});

/// A ordem de quitação: a lista inteira e quando foi decidida (RN-1031).
typedef DebtOrdering = ({List<String> ids, DateTime definedAt});

/// A ida e a volta das dívidas com o registro — o do aparelho e, desde a
/// ADR-019, o do servidor, que as guarda para o outro celular.
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
    // Só a dívida de saldo informado leva estes campos (ADR-023): quem lê
    // com um app antigo os ignora e continua abrindo.
    'balanceCents': ?debt.informedBalance?.cents,
    'informedOn': ?debt.informedOn?.toString(),
    'note': ?debt.note,
  };

  /// A dívida gravada em [payload]. Já foi aceita pelo domínio quando foi
  /// gravada.
  static Debt decodeDebt(Map<String, Object?> payload) {
    final debt = payload['balanceCents'] == null
        ? _byInstallments(payload)
        : _byBalance(payload);
    final payoff = payload['payoffCents'] as int?;
    if (payoff == null) return debt;
    return debt.withPayoffQuote(
      PayoffQuote(
        amount: Money.fromCents(payoff),
        quotedOn: EntryCodec.parseDate(payload['payoffQuotedOn']! as String),
      ),
    );
  }

  static Debt _byBalance(Map<String, Object?> payload) => Debt.withBalance(
    id: payload['id']! as String,
    creditor: payload['creditor']! as String,
    kind: EntryCodec.named(DebtKind.values, payload['kind']! as String),
    balance: Money.fromCents(payload['balanceCents']! as int),
    monthlyPayment: Money.fromCents(payload['installmentCents']! as int),
    dueDay: payload['dueDay']! as int,
    informedOn: EntryCodec.parseDate(payload['informedOn']! as String),
    note: payload['note'] as String?,
  ).valueOrNull!;

  static Debt _byInstallments(Map<String, Object?> payload) {
    return Debt.create(
      id: payload['id']! as String,
      creditor: payload['creditor']! as String,
      kind: EntryCodec.named(DebtKind.values, payload['kind']! as String),
      installmentAmount: Money.fromCents(payload['installmentCents']! as int),
      totalInstallments: payload['totalInstallments']! as int,
      paidInstallments: payload['paidInstallments']! as int,
      dueDay: payload['dueDay']! as int,
      firstMonth: EntryCodec.parseMonth(payload['firstMonth']! as String),
      cardId: payload['cardId'] as String?,
    ).valueOrNull!;
  }

  /// O que gravar para o pagamento de parcela [payment].
  static Map<String, Object?> encodePayment(DebtPayment payment) => {
    'debtId': payment.debtId,
    'entryId': payment.entryId,
  };

  /// O que gravar para a ordem de quitação [ordering].
  static Map<String, Object?> encodeOrdering(DebtOrdering ordering) => {
    'ids': ordering.ids,
    'definedAt': ordering.definedAt.toUtc().toIso8601String(),
  };

  /// A ordem de quitação gravada em [payload].
  static DebtOrdering decodeOrdering(Map<String, Object?> payload) => (
    ids: [for (final id in payload['ids']! as List<Object?>) id! as String],
    definedAt: DateTime.parse(payload['definedAt']! as String).toUtc(),
  );

  /// O pagamento de parcela gravado em [payload].
  static DebtPayment decodePayment(Map<String, Object?> payload) => (
    debtId: payload['debtId']! as String,
    entryId: payload['entryId']! as String,
  );
}
