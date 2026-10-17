import 'package:domain/domain.dart';

/// Um dia da lista de lançamentos: a data, o que foi lançado nela e quanto
/// contou, em dinheiro e em vale, separados (RN-111).
typedef EntryDay = ({LocalDate day, List<Entry> entries, TenderAmounts spent});

/// Os lançamentos agrupados por dia, do mais novo ao mais velho (17/10/2026).
///
/// O total do dia é o que o domínio diz que cada lançamento conta no mês
/// dele (`Entry.spentIn`): a compra parcelada entra com a parcela, como no
/// total do mês, e não inteira.
abstract final class EntryDays {
  /// Os dias de [entries], na ordem em que a lista já vem.
  static List<EntryDay> of(List<Entry> entries) {
    final days = <LocalDate, List<Entry>>{};
    for (final entry in entries) {
      (days[entry.occurredOn] ??= []).add(entry);
    }
    return [
      for (final MapEntry(key: day, value: list) in days.entries)
        (
          day: day,
          entries: list,
          spent: list.fold(
            TenderAmounts.zero,
            (sum, entry) => sum + entry.spentIn(day.budgetMonth),
          ),
        ),
    ];
  }
}
