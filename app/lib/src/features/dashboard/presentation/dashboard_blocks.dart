import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/budget/application/month_overview.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// Os números do painel, na ordem da pergunta que cada um responde: quanto
/// dá para gastar agora, como o mês fecha, quanto há de vale e quanto da
/// renda já tem dono.
///
/// Cada cartão mostra um número desde o primeiro dia: sem plano, o que há
/// é o gasto; sem renda, o cartão da sobra diz onde a renda se cadastra.
/// Nenhum cartão explica o que ele não é. O tom segue o guia de voz: falta
/// é "faltam R$ X para fechar", nunca alarme (D-UX-22).
abstract final class DashboardBlocks {
  /// Os cartões de [overview], de cima para baixo.
  static List<Widget> of(MonthOverview overview) => [
    _week(overview),
    _result(overview),
    _voucher(overview),
    if (overview.hasCards) _reserve(overview),
    if (overview.hasIncome) _committed(overview),
  ];

  /// A reserva da fatura: compra à vista no cartão já contou no dia em que
  /// foi feita (RN-310), mas o dinheiro ainda não saiu da conta. O cartão
  /// lembra que ele tem dono — e evita gastar duas vezes o mesmo dinheiro.
  static Widget _reserve(MonthOverview overview) => CajuiStatCard(
    label: 'Reserva da fatura',
    cents: overview.statementReserve.cents,
    caption:
        'Já comprado à vista no cartão, e ainda a pagar. Já está contado '
        'nos gastos: não é despesa nova.',
  );

  static String _brl(int cents) => BrlFormatter.format(cents);

  /// Sem faixa no plano não há limite de semana; o que há é o gasto do mês,
  /// que é o número que a pessoa veio ver.
  static Widget _week(MonthOverview overview) {
    final week = overview.week;
    if (overview.plan.variables.isEmpty) {
      return CajuiStatCard(
        label: 'Gasto do mês em dinheiro',
        cents: overview.spent.cash.cents,
        large: true,
        caption:
            'Com faixas no plano, aqui aparece quanto ainda dá para '
            'gastar na semana.',
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
      return CajuiStatCard(
        label: 'Sobra prevista de $month',
        caption: 'Cadastre a renda no plano do mês para ver quanto sobra.',
      );
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

  /// Só com renda: sem ela a proporção é indefinida — nunca 0%, nunca
  /// infinito (RN-604) —, e um cartão sem número só ocuparia lugar.
  static Widget _committed(MonthOverview overview) {
    final plan = overview.plan;
    final committed = plan.fixedTotal + plan.debtInstallments;
    final percent = overview.indicators.commitmentPercent;
    return CajuiStatCard(
      label: 'Renda comprometida',
      cents: committed.cents,
      meter: percent == null ? null : percent / 100,
      caption: percent == null
          ? 'Em fixos e dívidas.'
          : '$percent% da renda, em fixos e dívidas',
    );
  }
}
