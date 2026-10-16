import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

/// A ida e a volta do que **entrou**: o recebimento e o acerto do saldo do
/// vale.
///
/// Recebimento não é lançamento (RN-132): não tem categoria, não entra em
/// bloco de despesa e nunca se compensa com um gasto. Por isso viaja num
/// formato próprio, e não pelo `EntryCodec`.
abstract final class IncomeCodec {
  /// O que gravar para [receipt].
  static Map<String, Object?> encode(IncomeReceipt receipt) => {
    'id': receipt.id,
    'sourceId': receipt.sourceId,
    'tender': receipt.tender.name,
    'amountCents': receipt.amount.cents,
    'receivedOn': '${receipt.receivedOn}',
    // Só quando há nome: a entrada de antes viaja igual.
    'note': ?receipt.note,
  };

  /// O recebimento gravado em [payload].
  static IncomeReceipt decode(Map<String, Object?> payload) => IncomeReceipt(
    id: payload['id']! as String,
    sourceId: payload['sourceId'] as String?,
    tender: EntryCodec.named(Tender.values, payload['tender']! as String),
    amount: Money.fromCents(payload['amountCents']! as int),
    receivedOn: EntryCodec.parseDate(payload['receivedOn']! as String),
    note: payload['note'] as String?,
  );

  /// O recebimento vindo **de fora**, campo a campo (T-05).
  static IncomeReceipt read(Object? json) {
    final body = JsonReader(
      json,
      allowed: const {
        'id',
        'sourceId',
        'tender',
        'amountCents',
        'receivedOn',
        'note',
      },
    );
    final cents = body.integer('amountCents');
    if (cents <= 0) {
      throw const FormatException('campo "amountCents" não é positivo');
    }
    return IncomeReceipt(
      id: body.string('id', maxLength: 64),
      sourceId: body.optionalString('sourceId', maxLength: 64),
      tender: EntryCodec.named(Tender.values, body.string('tender')),
      amount: Money.fromCents(cents),
      receivedOn: EntryCodec.parseDate(body.string('receivedOn')),
      note: body.optionalString('note', maxLength: 40),
    );
  }

  /// O que gravar para um acerto de saldo do vale (RN-123).
  static Map<String, Object?> encodeAdjustment({
    required String id,
    required Money adjustment,
    required LocalDate on,
    required String reason,
  }) => {
    'id': id,
    'adjustmentCents': adjustment.cents,
    'on': '$on',
    'reason': reason,
  };

  /// O acerto gravado em [payload]. [orElse] é o identificador a usar quando
  /// o fato não traz um: registro antigo não tinha o campo, e não pode
  /// deixar de abrir por causa disso.
  static VoucherAdjustment decodeAdjustment(
    Map<String, Object?> payload, {
    required String orElse,
  }) => VoucherAdjustment(
    id: payload['id'] as String? ?? orElse,
    amount: Money.fromCents(payload['adjustmentCents']! as int),
    on: EntryCodec.parseDate(payload['on']! as String),
    reason: payload['reason']! as String,
  );

  /// O acerto vindo de fora. Aqui o valor **pode** ser negativo: acertar o
  /// saldo é justamente admitir que sobrou menos do que o app calculou.
  static Map<String, Object?> readAdjustment(Object? json) {
    final body = JsonReader(
      json,
      allowed: const {'id', 'adjustmentCents', 'on', 'reason'},
    );
    return encodeAdjustment(
      id: body.string('id', maxLength: 64),
      adjustment: Money.fromCents(body.integer('adjustmentCents')),
      // Passa pela leitura de data só para recusar dia impossível.
      on: EntryCodec.parseDate(body.string('on')),
      reason: body.string('reason', maxLength: 120),
    );
  }
}
