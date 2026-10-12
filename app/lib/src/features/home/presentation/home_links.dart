import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/budget/presentation/month_history_page.dart';
import 'package:cajui/src/features/budget/presentation/month_page.dart';
import 'package:cajui/src/features/budget/presentation/my_bills_page.dart';
import 'package:cajui/src/features/budget/presentation/voucher_page.dart';
import 'package:cajui/src/features/cards/presentation/cards_page.dart';
import 'package:cajui/src/features/debts/presentation/debts_page.dart';
import 'package:cajui/src/features/home/application/home_view.dart';
import 'package:cajui/src/features/ledger/presentation/entries_page.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// As portas do Início para o resto do app, as mesmas abas da planilha:
/// o mês, os lançamentos, minhas contas, os cartões, as dívidas e o mês a
/// mês. Cada uma diz numa frase o que tem lá dentro.
abstract final class HomeLinks {
  /// As linhas de [view]. [export] leva o mês para planilha.
  static List<Widget> of(
    BuildContext context,
    HomeView view, {
    required VoidCallback export,
  }) => [
    const CajuiSectionTitle('Seu dinheiro'),
    ..._month(context, view),
    ..._commitments(context, view),
    _spreadsheet(view, export),
  ];

  /// A planilha do mês (RN-1090) também mora aqui, e não só no rodapé do
  /// Meu mês: o dono pediu o botão sem saber que ele existia lá. Não abre
  /// tela — vai direto para o compartilhar —, e por isso o ícone é o de
  /// compartilhar, e não a seta das outras portas.
  static Widget _spreadsheet(HomeView view, VoidCallback export) {
    final month = DateLabels.month(view.budget.month).split(' ').first;
    return _row(
      title: 'Planilha do mês',
      subtitle: 'Leva $month para o Excel ou o Planilhas Google',
      open: export,
      icon: CajuiIconData.share,
    );
  }

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
      ?_voucher(context, view),
    ];
  }

  /// O vale só aparece para quem tem vale: no plano, ou com saldo.
  static Widget? _voucher(BuildContext context, HomeView view) {
    if (!view.budget.voucher.isPositive && !view.voucherBalance.isPositive) {
      return null;
    }
    // Sem crédito registrado o saldo é zero, e "Saldo de R$ 0,00" ao lado
    // de um vale de R$ 500 no plano confunde: aí o número é o do mês.
    final number = view.voucherBalance.isPositive
        ? 'Saldo de ${_brl(view.voucherBalance.cents)}'
        : 'Vale do mês ${_brl(view.budget.voucher.cents)}';
    return _row(
      title: 'Vale',
      subtitle: '$number · conferir com a operadora',
      open: () => VoucherPage.open(context),
    );
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
      subtitle: switch (view) {
        HomeView(owed: Money(isPositive: true)) =>
          'Ainda devo ${_brl(view.owed.cents)}',
        HomeView(hasDebts: true) => 'Tudo quitado',
        _ => 'Nenhuma dívida cadastrada',
      },
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
    CajuiIconData icon = CajuiIconData.chevronRight,
  }) => CajuiListRow(
    title: title,
    subtitle: subtitle,
    trailing: CajuiIcon(icon),
    semanticLabel: title,
    onPressed: open,
  );
}
