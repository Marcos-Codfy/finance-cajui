import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/budget/application/month_overview.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// Os quatro números do painel, na ordem da pergunta que cada um responde:
/// quanto dá para gastar agora, como o mês fecha, quanto há de vale e quanto
/// da renda já tem dono.
///
/// O tom segue o guia de voz: falta é "faltam R$ X para fechar", com o que
/// dá para fazer; nunca alarme, nunca julgamento (D-UX-22).
abstract final class DashboardBlocks {
  /// Os cartões de [overview], de cima para baixo.
  static List<Widget> of(MonthOverview overview) => [
    _week(overview),
    _result(overview),
    _voucher(overview),
    _committed(overview),
  ];

  static String _brl(int cents) => BrlFormatter.format(cents);

  static Widget _week(MonthOverview overview) {
    final week = overview.week;
    if (overview.plan.variables.isEmpty) {
      return const CajuiStatCard(
        label: 'Dá para gastar esta semana',
        large: true,
        caption: 'Aparece quando os gastos variáveis tiverem faixa no plano.',
      );
    }
    return CajuiStatCard(
      label: 'Dá para gastar esta semana',
      cents: week.remaining.orZeroIfNegative.cents,
      large: true,
      meter: week.limit.isPositive ? week.spent.cents / week.limit.cents : null,
      caption: _weekCaption(week),
    );
  }

  /// A frase da semana, em tom neutro nos três casos (RN-642 e RN-645): o
  /// variável do mês acabou, a semana passou do limite, ou está tudo dentro.
  static String _weekCaption(WeeklyLimit week) {
    if (week.monthOverrun.isPositive) {
      return 'O variável do mês já passou '
          '${_brl(week.monthOverrun.cents)} do plano.';
    }
    if (week.remaining.isNegative) {
      return 'A semana passou ${_brl(-week.remaining.cents)} do limite de '
          '${_brl(week.limit.cents)}.';
    }
    return '${_brl(week.spent.cents)} de ${_brl(week.limit.cents)} já usados';
  }

  static Widget _result(MonthOverview overview) {
    final month = DateLabels.month(overview.plan.month).split(' ').first;
    if (!overview.hasIncome) {
      return CajuiStatCard(label: 'Sobra prevista de $month');
    }
    final indicators = overview.indicators;
    final missing = indicators.requiredAdjustment;
    if (missing.isZero) {
      return CajuiStatCard(
        label: 'Sobra prevista de $month',
        cents: indicators.projectedResult.cents,
        tone: CajuiAmountTone.positive,
        caption: 'Contando os variáveis pelo pior caso',
      );
    }
    return CajuiStatCard(
      label: 'Faltam para fechar $month',
      cents: missing.cents,
      tone: CajuiAmountTone.shortfall,
      caption: indicators.closesByAdjustingVariables
          ? 'Dá para cobrir ajustando os variáveis, sem mexer nos fixos.'
          : 'Os variáveis sozinhos não cobrem: vale rever um fixo.',
    );
  }

  static Widget _voucher(MonthOverview overview) => CajuiStatCard(
    label: 'Vale alimentação',
    cents: overview.voucher.balance.cents,
    tone: CajuiAmountTone.accent,
    caption: 'só para alimentação · não se soma ao dinheiro',
    sunken: true,
  );

  static Widget _committed(MonthOverview overview) {
    final plan = overview.plan;
    final committed = plan.fixedTotal + plan.debtInstallments;
    final percent = overview.indicators.commitmentPercent;
    return CajuiStatCard(
      label: 'Renda comprometida',
      cents: committed.cents,
      meter: percent == null ? null : percent / 100,
      // Sem renda, a proporção é indefinida: nunca 0%, nunca infinito
      // (RN-604).
      caption: percent == null
          ? 'Em fixos e dívidas. A proporção aparece com a renda cadastrada.'
          : '$percent% da renda, em fixos e dívidas',
    );
  }
}
