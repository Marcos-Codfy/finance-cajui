import 'package:cajui/src/features/budget/presentation/month_history_page.dart';
import 'package:cajui/src/features/budget/presentation/month_page.dart';
import 'package:cajui/src/features/budget/presentation/my_bills_page.dart';
import 'package:cajui/src/features/cards/presentation/cards_page.dart';
import 'package:cajui/src/features/debts/presentation/debts_page.dart';
import 'package:cajui/src/features/home/application/home_view.dart';
import 'package:cajui/src/features/ledger/presentation/entries_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// As portas do Início para o resto do app, as mesmas abas da planilha:
/// o mês, os lançamentos, minhas contas, os cartões, as dívidas e o mês a
/// mês. Cada uma diz numa frase o que tem lá dentro.
abstract final class HomeLinks {
  /// As linhas de [view].
  static List<Widget> of(BuildContext context, HomeView view) => [
    const CajuiSectionTitle('Seu dinheiro'),
    ..._month(context, view),
    ..._commitments(context, view),
  ];

  static String _brl(int cents) => BrlFormatter.format(cents);

  /// O mês, os lançamentos e minhas contas.
  static List<Widget> _month(BuildContext context, HomeView view) {
    final budget = view.budget;
    return [
      _row(
        title: 'Meu mês',
        subtitle:
            'Entra ${_brl(budget.cashIncome.cents)} · sai do bolso '
            '${_brl(budget.outOfPocket.cents)}',
        open: () => MonthPage.open(context),
      ),
      _row(
        title: 'Lançamentos',
        subtitle: switch (view.entriesThisMonth) {
          0 => 'Nenhum este mês',
          1 => '1 este mês',
          final count => '$count este mês',
        },
        open: () => EntriesPage.open(context),
      ),
      _row(
        title: 'Minhas contas',
        subtitle: 'O que entra, o que sai todo mês e o dízimo',
        open: () => MyBillsPage.open(context),
      ),
    ];
  }

  /// Os cartões, as dívidas e o mês a mês.
  static List<Widget> _commitments(BuildContext context, HomeView view) => [
    _row(
      title: 'Cartões',
      subtitle: view.cardsNearLimit.isEmpty
          ? 'Quanto do limite já foi usado no mês'
          : '${view.cardsNearLimit.join(', ')} passou de 80% do limite',
      open: () => CardsPage.open(context),
    ),
    _row(
      title: 'Dívidas',
      subtitle: view.owed.isPositive
          ? 'Ainda devo ${_brl(view.owed.cents)}'
          : 'Nenhuma dívida cadastrada',
      open: () => DebtsPage.open(context),
    ),
    _row(
      title: 'Mês a mês',
      subtitle: 'Quanto entrou, saiu e sobrou em cada mês',
      open: () => MonthHistoryPage.open(context),
    ),
  ];

  static Widget _row({
    required String title,
    required String subtitle,
    required VoidCallback open,
  }) => CajuiListRow(
    title: title,
    subtitle: subtitle,
    trailing: const CajuiIcon(CajuiIconData.chevronRight),
    semanticLabel: title,
    onPressed: open,
  );
}
