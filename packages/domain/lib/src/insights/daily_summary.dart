import 'package:domain/src/calendar/calendar_words.dart';
import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/indicators/weekly_limit.dart';
import 'package:domain/src/ledger/entry.dart';
import 'package:domain/src/money/money_format.dart';
import 'package:domain/src/money/tender_amounts.dart';
import 'package:meta/meta.dart';

/// O resumo do dia (RN-810 a RN-815): curto, formular e sem IA.
///
/// Cada número vem do cálculo do domínio (RN-801); as frases saem de um
/// modelo fixo (RN-802). Dia sem lançamento é dito sem cobrança (RN-812), e
/// dinheiro e vale aparecem lado a lado, nunca somados (RN-804).
@immutable
final class DailySummary {
  /// O resumo de [day], a partir de [entries] e do que resta na semana.
  factory of(
    LocalDate day, {
    required Iterable<Entry> entries,
    WeeklyLimit? week,
    int pendingCaptures = 0,
  }) {
    final today = entries.where((entry) => entry.occurredOn == day).toList();
    return DailySummary._(
      day: day,
      entryCount: today.length,
      week: week,
      pendingCaptures: pendingCaptures,
      spent: today.fold(
        TenderAmounts.zero,
        (sum, entry) => sum + entry.paidByTender,
      ),
    );
  }

  const new _({
    required this.day,
    required this.spent,
    required this.entryCount,
    required this.week,
    required this.pendingCaptures,
  });

  /// O dia resumido.
  final LocalDate day;

  /// O gasto do dia, por moeda.
  final TenderAmounts spent;

  /// Quantos lançamentos o dia teve.
  final int entryCount;

  /// O limite da semana em curso (RN-642); `null` sem plano de variáveis.
  final WeeklyLimit? week;

  /// Quantos comprovantes esperam conferência.
  final int pendingCaptures;

  /// As frases do resumo, na ordem em que são lidas.
  List<String> get lines => [
    _spending,
    ?_week,
    if (pendingCaptures == 1) '1 comprovante esperando conferência.',
    if (pendingCaptures > 1)
      '$pendingCaptures comprovantes esperando conferência.',
  ];

  String get _spending {
    if (entryCount == 0) return 'Nada lançado hoje.';
    final count = entryCount == 1 ? '1 lançamento' : '$entryCount lançamentos';
    final parts = [
      if (spent.cash.isPositive) '${MoneyFormat.brl(spent.cash)} em dinheiro',
      if (spent.mealVoucher.isPositive)
        '${MoneyFormat.brl(spent.mealVoucher)} no vale',
    ];
    // Com uma moeda só, a frase fica curta: "Hoje: R$ 46,90 em 2
    // lançamentos." Com as duas, cada uma diz qual é.
    if (parts.length == 1 && spent.cash.isPositive) {
      return 'Hoje: ${MoneyFormat.brl(spent.cash)} em $count.';
    }
    return 'Hoje: ${parts.join(' · ')}, em $count.';
  }

  String? get _week {
    final limit = week;
    if (limit == null) return null;
    final remaining = limit.remaining;
    if (remaining.isNegative) {
      return 'A semana passou ${MoneyFormat.brl(-remaining)} do limite.';
    }
    // Semana partida pela virada do mês acaba antes de domingo (RN-644).
    final until = CalendarWords.weekday(limit.week.end);
    return 'Sobram ${MoneyFormat.brl(remaining)} até $until.';
  }
}
