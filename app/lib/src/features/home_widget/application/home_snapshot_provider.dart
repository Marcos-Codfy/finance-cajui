import 'package:cajui/src/features/budget/application/month_overview.dart';
import 'package:cajui/src/features/home_widget/application/home_snapshot.dart';
import 'package:cajui/src/features/review/application/review_providers.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O retrato que vai para o widget da tela inicial e para o aviso de
/// domingo; `null` enquanto o livro abre.
///
/// **É o único lugar que diz de onde sai o número do widget.** Hoje ele sai
/// de [monthOverviewProvider] — o mesmo limite da semana que o painel mostra
/// primeiro (RN-670). Quando o modelo do mês mudar, muda-se este provider e
/// mais nenhum: o publicador, o canal e o lado nativo só repassam o que ele
/// disser.
final homeSnapshotProvider = Provider<HomeSnapshot?>((ref) {
  final overview = ref.watch(monthOverviewProvider);
  if (overview == null) return null;
  final review = ref.watch(reviewItemsProvider);
  return _HomeWords.of(
    overview,
    reviewDates: [for (final entry in review) entry.occurredOn],
  );
});

/// As frases do widget. Sem valor do que passou do limite: o widget fica à
/// vista de quem olha a tela do celular, e o número de dentro do app basta
/// para isso (no espírito da RN-843).
abstract final class _HomeWords {
  static HomeSnapshot of(
    MonthOverview overview, {
    required List<LocalDate> reviewDates,
  }) {
    final week = overview.week;
    if (overview.plan.variables.isEmpty) {
      return HomeSnapshot(
        label: 'Gasto do mês',
        amount: MoneyFormat.brl(overview.spent.cash),
        caption: 'Com faixas no plano, aqui aparece o limite da semana.',
        validUntil: overview.today.budgetMonth.lastDay,
        reviewDates: reviewDates,
      );
    }
    return HomeSnapshot(
      label: 'Pode gastar esta semana',
      amount: MoneyFormat.brl(week.remaining.orZeroIfNegative),
      caption: _caption(week),
      validUntil: week.week.end,
      reviewDates: reviewDates,
    );
  }

  /// O mesmo tom do painel, nos três casos (RN-642 e RN-645).
  static String _caption(WeeklyLimit week) {
    if (week.monthOverrun.isPositive) {
      return 'O variável do mês já passou do plano.';
    }
    if (week.remaining.isNegative) {
      return 'A semana passou do limite. As próximas se ajustam.';
    }
    return '${MoneyFormat.brl(week.spent)} de '
        '${MoneyFormat.brl(week.limit)} já usados';
  }
}
