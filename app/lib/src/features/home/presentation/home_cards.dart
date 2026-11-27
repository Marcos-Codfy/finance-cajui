import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/budget/presentation/month_page.dart';
import 'package:cajui/src/features/home/application/home_view.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// Os números do Início, na ordem da planilha do dono, num carrossel 3D
/// (`CajuiCoverFlow`): se o mês fecha — a sobra, ou quanto falta —, a renda,
/// os gastos e o vale alimentação. Arrastar gira o tambor; o número da
/// frente é o que se lê. Cada página tem nome embaixo, e tocar no número
/// abre o Meu mês, com a conta por trás dele (27/11/2026).
///
/// O "pode gastar por semana" e o pote que o mostrava saíram em 11/10/2026,
/// a pedido do dono: ele não usava. Sem plano, o Início mostra o que já saiu
/// e diz onde se cadastra o resto — o plano não é obrigatório (RN-1050). O
/// tom é o do guia de voz: falta é "faltam R$ X para fechar", nunca alarme
/// (RN-1060).
abstract final class HomeCards {
  /// O carrossel de [view]. O mês no verde brilha — com festa quando
  /// [party] (escolha 5 do dono).
  /// A chave guarda a página escolhida quando um aviso aparece acima.
  static Widget of(
    HomeView view, {
    required VoidCallback onExplain,
    bool party = false,
  }) {
    final hasVoucher = view.budget.voucher.isPositive;
    return CajuiCoverFlow(
      key: const ValueKey('numeros-do-mes'),
      semanticLabel: 'Números do mês',
      pageLabels: [
        if (view.hasPlan) ...[
          _resultName(view),
          'Renda',
          'Gastos',
        ] else
          'Gastos',
        if (hasVoucher) 'Vale',
      ],
      children: [
        if (view.hasPlan)
          ..._sheet(view, party: party, onExplain: onExplain)
        else
          _spent(view, onExplain),
        if (hasVoucher) _voucher(view, onExplain),
      ],
    );
  }

  /// O convite ao toque, o mesmo em todas as páginas.
  static const _explain = 'Ver a conta';

  static String _resultName(HomeView view) =>
      view.budget.spentPercent != null && !view.budget.closes
      ? 'Falta'
      : 'Sobra';

  static String _brl(int cents) => BrlFormatter.format(cents);

  /// Sem plano não há sobra a dizer: o número é o que já saiu.
  static Widget _spent(HomeView view, VoidCallback onExplain) => CajuiStatCard(
    label: 'Gastos do mês',
    cents: view.budget.outOfPocket.cents,
    large: true,
    caption:
        'Cadastre sua renda e suas contas em Minhas contas para ver se o '
        'mês fecha.',
    onPressed: onExplain,
    actionLabel: _explain,
  );

  /// A planilha de relance: o resultado na frente, a renda e os gastos nos
  /// vizinhos. "Gastos" é o previsto do mês inteiro — contas, dia a dia e
  /// dívidas —, e a frase diz isso, para não brigar com o "já gasto" da
  /// tela de Lançamentos.
  static List<Widget> _sheet(
    HomeView view, {
    required bool party,
    required VoidCallback onExplain,
  }) {
    final budget = view.budget;
    return [
      _result(view, party: party, onExplain: onExplain),
      CajuiStatCard(
        label: 'Renda do mês',
        cents: budget.cashIncome.cents,
        large: true,
        caption: 'Em dinheiro: salários e o que mais entrou',
        onPressed: onExplain,
        actionLabel: _explain,
      ),
      CajuiStatCard(
        label: 'Gastos do mês',
        cents: budget.outOfPocket.cents,
        large: true,
        caption:
            'Previsto para o mês todo, em dinheiro · o vale alimentação '
            'cobre mais ${_brl(budget.voucherCovered.cents)}',
        onPressed: onExplain,
        actionLabel: _explain,
      ),
    ];
  }

  static Widget _result(
    HomeView view, {
    required bool party,
    required VoidCallback onExplain,
  }) {
    final budget = view.budget;
    final month = DateLabels.month(budget.month).split(' ').first;
    final percent = budget.spentPercent;
    if (percent == null) {
      return CajuiStatCard(
        label: 'Sobrou ou faltou em $month',
        large: true,
        caption: 'Cadastre sua renda em Minhas contas para ver se o mês fecha.',
      );
    }
    if (budget.closes) {
      return _leftOver(
        month,
        budget,
        percent,
        party: party,
        onExplain: onExplain,
      );
    }
    return _short(month, budget, percent, onExplain);
  }

  /// Falta não brilha: entra em silêncio, e a frase diz o que fazer.
  static Widget _short(
    String month,
    MonthBudget budget,
    int percent,
    VoidCallback onExplain,
  ) => CajuiStatCard(
    label: 'Faltam para fechar $month',
    cents: budget.shortfall.cents,
    large: true,
    tone: CajuiAmountTone.shortfall,
    caption: '$percent% da renda já está gasto. É a meta de corte do mês.',
    meter: _fill(percent),
    heroTag: MonthPage.resultTag,
    onPressed: onExplain,
    actionLabel: _explain,
  );

  /// A sobra brilha, e o número voa para o alto do Meu mês (escolhas 3 e 5
  /// do dono). A chave muda uma vez só, quando a festa começa: é o que a faz
  /// rodar à vista.
  static Widget _leftOver(
    String month,
    MonthBudget budget,
    int percent, {
    required bool party,
    required VoidCallback onExplain,
  }) => CajuiStatCard(
    key: ValueKey(('month-result', party)),
    label: 'Sobra de $month',
    cents: budget.result.cents,
    large: true,
    tone: CajuiAmountTone.positive,
    caption: 'Depois de pagar tudo · $percent% da renda já está gasto',
    meter: _fill(percent),
    heroTag: MonthPage.resultTag,
    glowing: true,
    celebrate: party,
    onPressed: onExplain,
    actionLabel: _explain,
  );

  /// A barra do quanto da renda já tem destino (16/10/2026): lê-se de
  /// relance, e a frase embaixo dela diz o mesmo em texto (RN-862). Passar
  /// de 100% enche a barra, sem alarme.
  static double _fill(int percent) => (percent / 100).clamp(0.0, 1.0);

  static Widget _voucher(HomeView view, VoidCallback onExplain) {
    final budget = view.budget;
    return CajuiStatCard(
      label: 'Vale alimentação do mês',
      cents: budget.voucher.cents,
      large: true,
      tone: CajuiAmountTone.accent,
      caption:
          '${_brl(budget.voucherCovered.cents)} cobre o mercado · não se '
          'soma ao dinheiro',
      sunken: true,
      onPressed: onExplain,
      actionLabel: _explain,
    );
  }
}
