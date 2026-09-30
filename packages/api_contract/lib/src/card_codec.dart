import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

/// A ida e a volta do cartão de crédito e do pagamento de fatura com o
/// registro.
///
/// Do cartão só se guarda o que o app precisa para calcular a fatura: nome,
/// dias e limite. **Número de cartão nunca existe no Cajui** — nem na tela,
/// nem no registro.
abstract final class CardCodec {
  /// O que gravar para [card].
  static Map<String, Object?> encodeCard(CreditCard card) => {
    'id': card.id,
    'name': card.name,
    'closingDay': card.closingDay,
    'dueDay': card.dueDay,
    'creditLimitCents': card.creditLimit?.cents,
  };

  /// O cartão gravado em [payload]. Já foi aceito pelo domínio quando foi
  /// gravado.
  static CreditCard decodeCard(Map<String, Object?> payload) {
    final limit = payload['creditLimitCents'] as int?;
    return CreditCard.create(
      id: payload['id']! as String,
      name: payload['name']! as String,
      closingDay: payload['closingDay']! as int,
      dueDay: payload['dueDay']! as int,
      creditLimit: limit == null ? null : Money.fromCents(limit),
    ).valueOrNull!;
  }

  /// O que gravar para [settlement].
  static Map<String, Object?> encodeSettlement(Settlement settlement) => {
    'id': settlement.id,
    'cardId': settlement.cardId,
    'dueMonth': '${settlement.dueMonth}',
    'amountCents': settlement.amount.cents,
    'paidOn': '${settlement.paidOn}',
  };

  /// O pagamento de fatura gravado em [payload].
  static Settlement decodeSettlement(Map<String, Object?> payload) {
    return Settlement(
      id: payload['id']! as String,
      cardId: payload['cardId']! as String,
      dueMonth: EntryCodec.parseMonth(payload['dueMonth']! as String),
      amount: Money.fromCents(payload['amountCents']! as int),
      paidOn: EntryCodec.parseDate(payload['paidOn']! as String),
    );
  }
}
