import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// A tela "Como o Cajui conta" da réplica: os mesmos assuntos do app, com
/// os mesmos exemplos inventados.
abstract final class HelpTexts {
  /// Os assuntos, na ordem em que a pessoa encontra os números no Painel.
  static const topics = [
    (
      'Renda do mês',
      'Tudo que entra em dinheiro no mês: salários e outras entradas que '
          'você cadastra em Minhas contas. O vale alimentação não entra aqui.',
    ),
    (
      'Gastos do mês',
      'O previsto para o mês inteiro, em dinheiro: contas fixas, '
          'assinaturas, parcelas, dízimo e o que a planilha reserva para o '
          'dia a dia, menos a parte do mercado que o vale alimentação paga.',
    ),
    (
      'Sobra ou falta',
      r'Renda do mês menos gastos do mês. Com renda de R$ 3.000,00 e gastos '
          r'de R$ 2.400,00, sobram R$ 600,00.',
    ),
    (
      'Já gasto (Lançamentos)',
      'O que você já lançou no mês, separado por moeda. É diferente de '
          '"Gastos do mês": aquele é o previsto, este é o que já saiu.',
    ),
    (
      'Vale alimentação',
      'É outra moeda. Ele paga mercado e alimentação, tem saldo próprio e '
          'nunca se soma ao dinheiro. Compra dividida entre vale e Pix conta '
          'cada parte na sua moeda.',
    ),
    (
      'Cartão de crédito',
      'Cartão é forma de pagamento, não despesa. A compra conta pelo que foi '
          'comprado, e a fatura é só a soma do que foi comprado no cartão.',
    ),
    (
      'Sincronização',
      'O que você lança fica guardado no celular na hora e sobe para o '
          'servidor quando há conexão. O aviso no alto do Início diz quando '
          'foi a última vez.',
    ),
  ];

  /// A tela, com o assunto [open] já aberto.
  static List<Widget> screen(BuildContext context, {String? open}) {
    final theme = CajuiTheme.of(context);
    final muted = theme.typography.body.copyWith(
      color: theme.colors.text.muted,
    );
    return [
      Text(
        'O que é cada número do app. Os valores dos exemplos são inventados.',
        style: muted,
      ),
      const SizedBox(height: CajuiSpacing.lg),
      for (final (title, text) in topics)
        CajuiDisclosure(
          title: title,
          initiallyOpen: title == open,
          children: [Text(text, style: muted)],
        ),
    ];
  }
}
