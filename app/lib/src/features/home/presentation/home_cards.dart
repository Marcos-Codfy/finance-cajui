import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/budget/presentation/month_page.dart';
import 'package:cajui/src/features/home/application/home_view.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// Os números do Início, na ordem da planilha do dono, num carrossel 3D
/// (`CajuiCoverFlow`): se o mês fecha — a sobra, ou quanto falta —, o que
/// entra, o que sai do bolso e o vale. Arrastar gira o tambor; o número da
/// frente é o que se lê.
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
  static Widget of(HomeView view, {bool party = false}) => CajuiCoverFlow(
    key: const ValueKey('numeros-do-mes'),
    semanticLabel: 'Números do mês',
    children: [
      if (view.hasPlan) ..._sheet(view, party: party) else _spent(view),
      if (view.budget.voucher.isPositive) _voucher(view),
    ],
  );

  static String _brl(int cents) => BrlFormatter.format(cents);

  /// Sem plano não há sobra a dizer: o número é o que já saiu.
  static Widget _spent(HomeView view) => CajuiStatCard(
    label: 'Já saiu este mês',
    cents: view.budget.outOfPocket.cents,
    large: true,
    caption:
        'Cadastre o que entra e suas contas em Minhas contas para ver se o '
        'mês fecha.',
  );

  /// A planilha de relance: o resultado na frente, o que entra e o que sai
  /// nos vizinhos.
  static List<Widget> _sheet(HomeView view, {required bool party}) {
    final budget = view.budget;
    return [
      _result(view, party: party),
      CajuiStatCard(
        label: 'O que entra',
        cents: budget.cashIncome.cents,
        large: true,
        caption: 'Em dinheiro, pelo que está em Minhas contas e no recebido',
      ),
      CajuiStatCard(
        label: 'O que sai do bolso',
        cents: budget.outOfPocket.cents,
        large: true,
        caption:
            'Sai ${_brl(budget.totalOut.cents)} · o vale paga '
            '${_brl(budget.voucherCovered.cents)}',
      ),
    ];
  }

  static Widget _result(HomeView view, {required bool party}) {
    final budget = view.budget;
    final month = DateLabels.month(budget.month).split(' ').first;
    final percent = budget.spentPercent;
    if (percent == null) {
      return CajuiStatCard(
        label: 'Sobrou ou faltou em $month',
        large: true,
        caption:
            'Cadastre o que entra em Minhas contas para ver se o mês '
            'fecha.',
      );
    }
    if (budget.closes) return _leftOver(month, budget, percent, party: party);
    // Falta não brilha: entra em silêncio, e a frase diz o que fazer.
    return CajuiStatCard(
      label: 'Faltam para fechar $month',
      cents: budget.shortfall.cents,
      large: true,
      tone: CajuiAmountTone.shortfall,
      caption: '$percent% da renda já está gasto. É a meta de corte do mês.',
      heroTag: MonthPage.resultTag,
    );
  }

  /// A sobra brilha, e o número voa para o alto do Meu mês (escolhas 3 e 5
  /// do dono). A chave muda uma vez só, quando a festa começa: é o que a faz
  /// rodar à vista.
  static Widget _leftOver(
    String month,
    MonthBudget budget,
    int percent, {
    required bool party,
  }) => CajuiStatCard(
    key: ValueKey(('month-result', party)),
    label: 'Sobra de $month',
    cents: budget.result.cents,
    large: true,
    tone: CajuiAmountTone.positive,
    caption: 'Depois de pagar tudo · $percent% da renda já está gasto',
    heroTag: MonthPage.resultTag,
    glowing: true,
    celebrate: party,
  );

  static Widget _voucher(HomeView view) {
    final budget = view.budget;
    return CajuiStatCard(
      label: 'Vale do mês',
      cents: budget.voucher.cents,
      large: true,
      tone: CajuiAmountTone.accent,
      caption:
          '${_brl(budget.voucherCovered.cents)} cobre o mercado · não se '
          'soma ao dinheiro',
      sunken: true,
    );
  }
}
