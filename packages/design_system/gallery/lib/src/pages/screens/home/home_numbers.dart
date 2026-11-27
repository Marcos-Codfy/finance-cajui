import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Os números do Início, como o app os mostra: num carrossel 3D, na ordem da
/// planilha do dono — se o mês fecha, a renda, os gastos e o vale
/// alimentação —, com o nome de cada página embaixo e o "Ver a conta" que
/// leva ao Meu mês.
///
/// O mês é outubro de alguém que recebe R$ 3.700,00 de salário e um freela
/// de R$ 500,00, tem R$ 600,00 de vale e paga as contas do bolso. As contas
/// fecham entre si: a sobra é a renda menos os gastos, e os gastos são o
/// total que sai menos o que o vale cobre. O vale nunca
/// entra em soma nenhuma do dinheiro (RN-111).
abstract final class HomeNumbers {
  /// A renda em dinheiro: salário e freela.
  static const int income = 420000;

  /// O vale do mês. Cobre o mercado inteiro, que passou de R$ 600,00.
  static const int voucher = 60000;

  /// O total que sai: contas fixas, assinaturas, dia a dia e dízimo.
  static const int totalOut = 348760;

  /// O que precisa sair do bolso: o total menos o que o vale cobre.
  static const int outOfPocket = totalOut - voucher;

  /// A sobra de outubro: R$ 1.312,40.
  static const int leftover = income - outOfPocket;

  /// No mês que não fecha, o total que sai.
  static const int tightTotalOut = 509400;

  /// No mês que não fecha, os gastos em dinheiro: R$ 4.494,00.
  static const int tightOutOfPocket = tightTotalOut - voucher;

  /// O que já saiu nos primeiros dias de uso, antes de haver plano.
  static const int firstSpent = 34250;

  static String _brl(int cents) => BrlFormatter.format(cents);

  static void _nothing() {}

  /// O carrossel com [pages]. A chave guarda a página escolhida quando um
  /// aviso aparece acima, como no app.
  static Widget carousel(List<Widget> pages) => CajuiCoverFlow(
    key: const ValueKey('numeros-do-mes'),
    semanticLabel: 'Números do mês',
    pageLabels: [
      for (final (index, _) in pages.indexed)
        const ['Sobra', 'Renda', 'Gastos', 'Vale'][index],
    ],
    children: pages,
  );

  /// O mês no verde. A sobra brilha; com [party], faz a festa ao aparecer,
  /// como na primeira vez em que o mês fecha (escolha 5 do dono).
  static List<Widget> closing({bool party = false}) => [
    CajuiStatCard(
      key: ValueKey(('month-result', party)),
      label: 'Sobra de outubro',
      cents: leftover,
      large: true,
      tone: CajuiAmountTone.positive,
      caption: 'Depois de pagar tudo · 69% da renda já está gasto',
      glowing: true,
      celebrate: party,
    ),
    comesIn(income),
    goesOut(totalOut),
    voucherCard(),
  ];

  /// O mês que não fecha: a falta entra em silêncio, sem brilho, e a frase
  /// diz o que fazer com ela (RN-1060).
  static List<Widget> short() => [
    const CajuiStatCard(
      label: 'Faltam para fechar outubro',
      cents: tightOutOfPocket - income,
      large: true,
      tone: CajuiAmountTone.shortfall,
      caption: '107% da renda já está gasto. É a meta de corte do mês.',
    ),
    comesIn(income),
    goesOut(tightTotalOut),
    voucherCard(),
  ];

  /// Sem renda cadastrada, a proporção não existe: o cartão mostra um
  /// travessão, e nunca 0% nem infinito (RN-604).
  static List<Widget> noIncome() => [
    const CajuiStatCard(
      label: 'Sobrou ou faltou em outubro',
      large: true,
      caption: 'Cadastre sua renda em Minhas contas para ver se o mês fecha.',
    ),
    comesIn(0),
    goesOut(totalOut),
    voucherCard(),
  ];

  /// Sem plano, não há sobra a dizer: o número é o que já saiu, e a frase
  /// diz onde se cadastra o resto. O plano não é obrigatório (RN-1050).
  static List<Widget> noPlan() => [
    const CajuiStatCard(
      label: 'Gastos do mês',
      cents: firstSpent,
      large: true,
      caption:
          'Cadastre sua renda e suas contas em Minhas contas para ver se o '
          'mês fecha.',
    ),
  ];

  /// A renda, em dinheiro.
  static Widget comesIn(int cents) => CajuiStatCard(
    label: 'Renda do mês',
    cents: cents,
    large: true,
    caption: 'Em dinheiro: salários e o que mais entrou',
    onPressed: _nothing,
    actionLabel: 'Ver a conta',
  );

  /// Os gastos: o total previsto menos o que o vale paga.
  static Widget goesOut(int total) => CajuiStatCard(
    label: 'Gastos do mês',
    cents: total - voucher,
    large: true,
    caption:
        'Previsto para o mês todo, em dinheiro · o vale alimentação '
        'cobre mais ${_brl(voucher)}',
    onPressed: _nothing,
    actionLabel: 'Ver a conta',
  );

  /// O vale: outra moeda, rebaixada ao lado do dinheiro.
  static Widget voucherCard() => CajuiStatCard(
    label: 'Vale alimentação do mês',
    cents: voucher,
    large: true,
    tone: CajuiAmountTone.accent,
    caption: '${_brl(voucher)} cobre o mercado · não se soma ao dinheiro',
    sunken: true,
  );
}
