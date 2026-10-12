import 'package:api_contract/src/entry_codec.dart';
import 'package:domain/domain.dart';

/// Um recebimento desfeito: qual, e em que dia (RN-1120).
typedef IncomeCancellation = ({String receiptId, LocalDate on});

/// A ida e a volta do fato "recebimento desfeito" (RN-1120, ADR-030).
///
/// Viaja como fato do aparelho, e não como uma rota de recebimento a mais:
/// o servidor só precisa saber qual recebimento deixou de valer, e é dele
/// que tira o valor dos números da Juju. O recebimento original não é
/// apagado — desfazer é acrescentar, como cancelar um lançamento (RN-208).
abstract final class IncomeCancellationCodec {
  /// O que gravar para [cancellation].
  static Map<String, Object?> encode(IncomeCancellation cancellation) => {
    'receiptId': cancellation.receiptId,
    'on': '${cancellation.on}',
  };

  /// O fato gravado em [payload]. O identificador tem o mesmo teto do
  /// recebimento que ele desfaz.
  static IncomeCancellation decode(Map<String, Object?> payload) {
    final id = payload['receiptId'];
    final on = payload['on'];
    if (id is! String || id.trim().isEmpty || id.length > _maxId) {
      throw const FormatException('recebimento desfeito');
    }
    if (on is! String) throw const FormatException('dia em que foi desfeito');
    return (receiptId: id, on: EntryCodec.parseDate(on));
  }

  static const _maxId = 64;
}
