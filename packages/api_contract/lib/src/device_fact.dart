import 'package:api_contract/src/card_codec.dart';
import 'package:api_contract/src/debt_codec.dart';
import 'package:api_contract/src/json_reader.dart';
import 'package:api_contract/src/month_close_codec.dart';
import 'package:meta/meta.dart';

/// Um fato que o servidor **guarda e devolve sem fazer conta com ele**: a
/// fatura paga, a dívida cadastrada, a parcela de dívida paga e o mês
/// fechado (ADR-019).
///
/// São fatos que só o aparelho interpreta — o servidor não responde nada a
/// partir deles. Ele os guarda por um motivo só: para o outro celular, e o
/// celular reinstalado, terem de onde trazê-los. Sem isto, quem cadastrava
/// as dívidas num aparelho cadastrava de novo no outro.
///
/// Guardar sem interpretar não é guardar sem conferir (T-05): o conteúdo
/// passa pelo mesmo codec que o aparelho usa, e o que não fecha é recusado.
@immutable
final class DeviceFact {
  /// Cria o fato [id], do tipo [type], com o conteúdo [payload].
  const new({required this.id, required this.type, required this.payload});

  /// Lê o fato, recusando o que estiver fora do formato (`E-REQ-01`): campo
  /// a mais, tipo que não é um dos quatro, conteúdo que o codec do tipo não
  /// aceita. O conteúdo volta **normalizado** — só o que o codec conhece.
  factory read(Object? json) {
    final reader = JsonReader(json, allowed: const {'id', 'type', 'payload'});
    final type = reader.string('type', maxLength: 32);
    final raw = (json! as Map<String, Object?>)['payload'];
    if (!types.contains(type) || raw is! Map) {
      throw FormatException('fato: $type');
    }
    return DeviceFact(
      id: reader.string('id', maxLength: 96),
      type: type,
      payload: _normalized(type, raw.cast<String, Object?>()),
    );
  }

  /// O tipo do fato "fatura paga".
  static const statementSettled = 'statement.settled';

  /// O tipo do fato "dívida cadastrada".
  static const debtDefined = 'debt.defined';

  /// O tipo do fato "parcela de dívida paga".
  static const debtInstallmentPaid = 'debt.installment-paid';

  /// O tipo do fato "mês fechado".
  static const monthClosed = 'month.closed';

  /// Os tipos que o servidor aceita guardar assim, e só eles.
  static const Set<String> types = {
    statementSettled,
    debtDefined,
    debtInstallmentPaid,
    monthClosed,
  };

  /// O identificador do fato: o mesmo do registro do aparelho que o gravou.
  final String id;

  /// O tipo, um de [types].
  final String type;

  /// O conteúdo, no formato do codec do tipo.
  final Map<String, Object?> payload;

  /// O fato em JSON.
  Map<String, Object?> toJson() => {'id': id, 'type': type, 'payload': payload};

  /// O conteúdo lido e escrito de novo pelo codec do tipo. Qualquer tropeço
  /// — campo que falta, tipo errado, valor que o domínio recusa — é pedido
  /// malformado, e não erro de quem lê.
  static Map<String, Object?> _normalized(
    String type,
    Map<String, Object?> payload,
  ) {
    try {
      return switch (type) {
        statementSettled => CardCodec.encodeSettlement(
          CardCodec.decodeSettlement(payload),
        ),
        debtDefined => DebtCodec.encodeDebt(DebtCodec.decodeDebt(payload)),
        debtInstallmentPaid => DebtCodec.encodePayment(
          DebtCodec.decodePayment(payload),
        ),
        _ => MonthCloseCodec.encode(MonthCloseCodec.decode(payload)),
      };
    } on Object {
      throw FormatException('fato: $type');
    }
  }
}
