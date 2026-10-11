import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/home/application/home_view.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Os números do Início, na ordem da planilha do dono: quanto dá para gastar
/// nesta semana, se o mês fecha, e o vale.
///
/// Sem plano, o Início mostra o que já saiu e diz onde se cadastra o resto
/// — o plano não é obrigatório (RN-1050). O tom é o do guia de voz: falta é
/// "faltam R$ X para fechar", nunca alarme (RN-1060).
abstract final class HomeCards {
  /// Os cartões de [view], de cima para baixo.
  static List<Widget> of(HomeView view) => [
    _week(view),
    const SizedBox(height: CajuiSpacing.lg),
    _result(view),
    if (view.budget.voucher.isPositive) ...[
      const SizedBox(height: CajuiSpacing.lg),
      _voucher(view),
    ],
  ];

  static String _brl(int cents) => BrlFormatter.format(cents);

  static Widget _week(HomeView view) {
    if (!view.hasPlan) {
      return CajuiStatCard(
        label: 'Já saiu este mês',
        cents: view.budget.outOfPocket.cents,
        large: true,
        caption:
            'Cadastre o que entra e suas contas em Minhas contas para ver '
            'quanto dá para gastar por semana.',
      );
    }
    final week = view.week;
    return CajuiStatCard(
      label: 'Pode gastar esta semana',
      cents: week.left.cents,
      large: true,
      meter: week.limit.isPositive ? (100 - week.leftPercent) / 100 : null,
      caption: _weekCaption(view),
    );
  }

  /// A frase da semana, em tom neutro: passou do limite, ou quanto já foi.
  static String _weekCaption(HomeView view) {
    final week = view.week;
    if (week.over.isPositive) {
      return 'A semana passou ${_brl(week.over.cents)} do limite de '
          '${_brl(week.limit.cents)}.';
    }
    final voucher = view.budget.weeklyVoucher;
    final part = voucher.isPositive
        ? ' · ${_brl(voucher.cents)} do limite é vale'
        : '';
    return '${_brl(week.spent.cents)} de ${_brl(week.limit.cents)} já '
        'gastos$part';
  }

  static Widget _result(HomeView view) {
    final budget = view.budget;
    final month = DateLabels.month(budget.month).split(' ').first;
    final percent = budget.spentPercent;
    if (percent == null) {
      return CajuiStatCard(
        label: 'Sobrou ou faltou em $month',
        caption:
            'Cadastre o que entra em Minhas contas para ver se o mês '
            'fecha.',
      );
    }
    if (budget.closes) {
      return CajuiStatCard(
        label: 'Sobra de $month',
        cents: budget.result.cents,
        tone: CajuiAmountTone.positive,
        caption: 'Depois de pagar tudo · $percent% da renda já está gasto',
      );
    }
    return CajuiStatCard(
      label: 'Faltam para fechar $month',
      cents: budget.shortfall.cents,
      tone: CajuiAmountTone.shortfall,
      caption: '$percent% da renda já está gasto. É a meta de corte do mês.',
    );
  }

  static Widget _voucher(HomeView view) {
    final budget = view.budget;
    return CajuiStatCard(
      label: 'Vale do mês',
      cents: budget.voucher.cents,
      tone: CajuiAmountTone.accent,
      caption:
          '${_brl(budget.voucherCovered.cents)} cobre o mercado · não se '
          'soma ao dinheiro',
      sunken: true,
    );
  }
}
