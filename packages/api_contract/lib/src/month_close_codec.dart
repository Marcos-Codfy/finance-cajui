import 'package:api_contract/src/entry_codec.dart';
import 'package:domain/domain.dart';

/// A ida e a volta do fechamento do mês com o registro.
///
/// Cada revisão é gravada por inteiro, e nenhuma apaga a anterior: é assim
/// que a diferença entre duas revisões continua existindo depois de um
/// lançamento tardio (RN-441).
abstract final class MonthCloseCodec {
  /// O que gravar para [close].
  static Map<String, Object?> encode(MonthClose close) => {
    'month': '${close.month}',
    'revision': close.revision,
    'cashResultCents': close.cashResult.cents,
    'closedOn': '${close.closedOn}',
  };

  /// O fechamento gravado em [payload].
  static MonthClose decode(Map<String, Object?> payload) {
    return MonthClose.restore(
      month: EntryCodec.parseMonth(payload['month']! as String),
      revision: payload['revision']! as int,
      cashResult: Money.fromCents(payload['cashResultCents']! as int),
      closedOn: EntryCodec.parseDate(payload['closedOn']! as String),
    );
  }
}
