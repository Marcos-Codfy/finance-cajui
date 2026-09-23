import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

/// A ida e a volta de um **estorno**: dinheiro de uma compra que voltou.
///
/// O estorno não altera o lançamento original (RN-208): é um fato próprio,
/// ligado a ele, que reduz o gasto da categoria no mês da **data do
/// estorno** (RN-209) e volta pela mesma forma de pagamento (RN-211).
///
/// Viaja com o identificador da linha e o valor, e **não** com o estorno
/// pronto: quem monta o `Reversal` é o domínio, dos dois lados, a partir do
/// lançamento original — é ele que sabe se ainda resta o que estornar
/// (RN-210).
abstract final class ReversalCodec {
  /// O que gravar para [reversal].
  static Map<String, Object?> encode(Reversal reversal) => {
    'id': reversal.id,
    'entryId': reversal.entryId,
    'paymentMethodId': reversal.line.paymentMethodId,
    'amountCents': reversal.line.amount.cents,
    'occurredOn': '${reversal.occurredOn}',
  };

  /// O estorno gravado em [payload], sobre o lançamento [entry].
  ///
  /// Devolve o `Result` do domínio: recusa por passar do que resta continua
  /// sendo falha de regra, e não exceção.
  static Result<Reversal> decode(
    Map<String, Object?> payload, {
    required Entry entry,
    Iterable<Reversal> previous = const [],
  }) => Reversal.create(
    id: payload['id']! as String,
    entry: entry,
    paymentMethodId: payload['paymentMethodId']! as String,
    amount: Money.fromCents(payload['amountCents']! as int),
    occurredOn: EntryCodec.parseDate(payload['occurredOn']! as String),
    previous: previous,
  );

  /// O estorno vindo **de fora**, campo a campo (T-05). Devolve o payload
  /// já conferido; quem aplica as regras é [decode], com o lançamento em mãos.
  static Map<String, Object?> read(Object? json) {
    final body = JsonReader(
      json,
      allowed: const {
        'id',
        'entryId',
        'paymentMethodId',
        'amountCents',
        'occurredOn',
      },
    );
    final cents = body.integer('amountCents');
    if (cents <= 0) {
      throw const FormatException('campo "amountCents" não é positivo');
    }
    return {
      'id': body.string('id', maxLength: 64),
      'entryId': body.string('entryId', maxLength: 64),
      'paymentMethodId': body.string('paymentMethodId', maxLength: 64),
      'amountCents': cents,
      // Passa pela leitura de data só para recusar dia impossível.
      'occurredOn': '${EntryCodec.parseDate(body.string('occurredOn'))}',
    };
  }
}
