import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:domain/domain.dart';

/// A ida e a volta dos fatos que **mexem num lançamento já gravado**:
/// correção, cancelamento e estorno (RN-208 a RN-211).
///
/// Nenhum deles reescreve o fato original. O registro guarda o lançamento
/// como nasceu e, depois, o que aconteceu com ele.
abstract final class EntryFactCodec {
  /// O que gravar para a correção [event]: o lançamento como passa a valer,
  /// no formato do contrato, mais o dia e o que mudou.
  static Map<String, Object?> encodeCorrection(EntryCorrected event) => {
    'on': '${event.on}',
    'reason': event.reason,
    'entry': EntryCodec.fromEntry(event.entry).toJson(),
  };

  /// A correção gravada. [toEntry] refaz o lançamento a partir do conteúdo
  /// no formato do contrato.
  static EntryCorrected decodeCorrection(
    String id,
    Map<String, Object?> payload,
    Entry Function(Map<String, Object?> entry) toEntry,
  ) {
    return EntryCorrected(
      id: id,
      entry: toEntry((payload['entry']! as Map).cast<String, Object?>()),
      on: EntryCodec.parseDate(payload['on']! as String),
      reason: payload['reason']! as String,
    );
  }

  /// O que gravar para o cancelamento [event].
  static Map<String, Object?> encodeCancellation(EntryCancelled event) => {
    'entryId': event.entryId,
    'on': '${event.on}',
    'reason': event.reason,
  };

  /// O cancelamento gravado.
  static EntryCancelled decodeCancellation(
    String id,
    Map<String, Object?> payload,
  ) {
    return EntryCancelled(
      id: id,
      entryId: payload['entryId']! as String,
      on: EntryCodec.parseDate(payload['on']! as String),
      reason: payload['reason']! as String,
    );
  }

  /// O que gravar para o estorno [reversal].
  static Map<String, Object?> encodeReversal(Reversal reversal) => {
    'id': reversal.id,
    'entryId': reversal.entryId,
    'paymentMethodId': reversal.line.paymentMethodId,
    'amountCents': reversal.line.amount.cents,
    'occurredOn': '${reversal.occurredOn}',
  };

  /// O estorno gravado; `null` quando o lançamento dele não está mais no
  /// livro. [entryOf] acha um lançamento **já lido** do registro.
  ///
  /// O limite da RN-210 foi conferido quando o estorno foi aceito; relê-lo
  /// não confere de novo.
  static EntryReversed? decodeReversal(
    Map<String, Object?> payload,
    Entry? Function(String id)? entryOf,
  ) {
    final entry = entryOf?.call(payload['entryId']! as String);
    if (entry == null) return null;
    final reversal = Reversal.create(
      id: payload['id']! as String,
      entry: entry,
      paymentMethodId: payload['paymentMethodId']! as String,
      amount: Money.fromCents(payload['amountCents']! as int),
      occurredOn: EntryCodec.parseDate(payload['occurredOn']! as String),
    ).valueOrNull;
    return reversal == null ? null : EntryReversed(reversal);
  }
}
