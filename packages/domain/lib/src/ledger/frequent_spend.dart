import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/ledger/entry.dart';
import 'package:domain/src/ledger/possible_duplicate.dart';
import 'package:domain/src/money/money.dart';
import 'package:meta/meta.dart';

/// Um gasto que se repete — o mercado da semana, o ônibus, a padaria —,
/// pronto para ser lançado de novo com um toque.
///
/// Quem lança o mesmo gasto toda semana não deveria digitar o mesmo nome, a
/// mesma categoria e a mesma forma de pagamento toda vez. O valor proposto
/// é o da última vez, e não a média: é o que a pessoa lembra de ter pago, e
/// a média dá um número que nunca apareceu em comprovante nenhum.
@immutable
final class FrequentSpend {
  /// Cria a sugestão.
  const new({
    required this.description,
    required this.categoryId,
    required this.paymentMethodId,
    required this.amount,
    required this.count,
  });

  /// Quantos dias para trás se olha: dois meses pegam o que é hábito, e não
  /// o que foi hábito um dia.
  static const lookbackDays = 60;

  /// A partir de quantas vezes um gasto é hábito.
  static const minimumCount = 2;

  /// A descrição como foi escrita da última vez.
  final String description;

  /// A categoria da última vez.
  final String categoryId;

  /// A forma de pagamento da última vez (a primeira linha, se foi dividida).
  final String paymentMethodId;

  /// O valor da última vez.
  final Money amount;

  /// Quantas vezes apareceu no período.
  final int count;

  /// Os gastos mais repetidos de [entries] nos últimos [lookbackDays] dias
  /// até [today], do mais frequente para o menos — no empate, o mais
  /// recente na frente —, no máximo [limit].
  ///
  /// Sem nenhum repetido, a sugestão é o último lançamento: "repetir o
  /// último" também poupa digitação. Sem lançamento nenhum, a lista é vazia.
  static List<FrequentSpend> rank(
    Iterable<Entry> entries, {
    required LocalDate today,
    int limit = 4,
  }) {
    final since = today.addDays(-lookbackDays);
    final recent = [
      for (final entry in entries)
        if (!entry.occurredOn.isBefore(since) &&
            !entry.occurredOn.isAfter(today))
          entry,
    ]..sort((a, b) => b.occurredOn.compareTo(a.occurredOn));
    final groups = <String, List<Entry>>{};
    for (final entry in recent) {
      final key = PossibleDuplicate.normalize(entry.description);
      if (key.isNotEmpty) (groups[key] ??= []).add(entry);
    }
    final ranked = [
      for (final group in groups.values)
        if (group.length >= minimumCount) _of(group.first, group.length),
    ]..sort((a, b) => b.count.compareTo(a.count));
    if (ranked.isEmpty && recent.isNotEmpty) return [_of(recent.first, 1)];
    return ranked.take(limit).toList();
  }

  /// A lista já vem do mais recente para o mais antigo, e o `sort` do Dart
  /// é estável: no empate de contagem, o mais recente continua na frente.
  static FrequentSpend _of(Entry last, int count) => FrequentSpend(
    description: last.description,
    categoryId: last.categoryId,
    paymentMethodId: last.paymentLines.first.paymentMethodId,
    amount: last.amount,
    count: count,
  );
}
