import 'package:cajui/src/features/home/application/home_view.dart';
import 'package:cajui/src/features/home_widget/application/home_snapshot.dart';
import 'package:cajui/src/features/review/application/review_providers.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O retrato que vai para o widget da tela inicial e para o aviso de
/// domingo; `null` enquanto o livro abre.
///
/// **É o único lugar que diz de onde sai o número do widget.** Ele sai de
/// [homeViewProvider] — o mesmo "pode gastar esta semana" que o Início
/// mostra primeiro (RN-1011). O publicador, o canal e o lado nativo só
/// repassam o que ele disser.
final homeSnapshotProvider = Provider<HomeSnapshot?>((ref) {
  final view = ref.watch(homeViewProvider);
  if (view == null) return null;
  final review = ref.watch(reviewItemsProvider);
  return _HomeWords.of(
    view,
    reviewDates: [for (final entry in review) entry.occurredOn],
  );
});

/// As frases do widget. Sem valor do que passou do limite: o widget fica à
/// vista de quem olha a tela do celular, e o número de dentro do app basta
/// para isso (no espírito da RN-843).
abstract final class _HomeWords {
  static HomeSnapshot of(
    HomeView view, {
    required List<LocalDate> reviewDates,
  }) {
    // Sem plano, o widget mostra o que já saiu, como o Início (RN-1050).
    if (!view.hasPlan) {
      return HomeSnapshot(
        label: 'Já saiu este mês',
        amount: MoneyFormat.brl(view.budget.outOfPocket),
        caption: 'Com Minhas contas, aqui aparece o limite da semana.',
        validUntil: view.today.budgetMonth.lastDay,
        reviewDates: reviewDates,
      );
    }
    final week = view.week;
    return HomeSnapshot(
      label: 'Pode gastar esta semana',
      amount: MoneyFormat.brl(week.left),
      caption: _caption(week),
      validUntil: week.until,
      reviewDates: reviewDates,
    );
  }

  /// O mesmo tom do Início (RN-1060): nunca alarme.
  static String _caption(WeekAllowance week) {
    if (week.over.isPositive) {
      return 'A semana passou do limite de ${MoneyFormat.brl(week.limit)}.';
    }
    return '${MoneyFormat.brl(week.spent)} de '
        '${MoneyFormat.brl(week.limit)} já gastos';
  }
}
