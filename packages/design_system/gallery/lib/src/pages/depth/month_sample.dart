import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/home/home_numbers.dart';

/// Um mês de mentira, mas verossímil, para os efeitos de profundidade:
/// outubro de alguém que recebe salário e um freela, paga aluguel e usa o
/// vale no mercado.
///
/// É o mesmo mês do Início da gallery ([HomeNumbers]): quem passa de uma
/// página para a outra vê os mesmos números, como no app. O vale aparece à
/// parte, como outra moeda, e nunca entra em total nenhum (RN-111).
abstract final class MonthSample {
  /// Os quatro números do mês, um por página do carrossel, como no Início.
  static List<Widget> numbers() => HomeNumbers.closing();

  /// As contas fixas do mês, com o dízimo de 10% do que entra.
  static const List<(String, String, int)> bills = [
    ('Aluguel', 'vence dia 5', 110000),
    ('Dízimo', 'dia 10', 42000),
    ('Luz', 'vence dia 12', 14230),
    ('Internet', 'vence dia 15', 9990),
    ('Plano do celular', 'vence dia 20', 4990),
  ];

  /// Os últimos lançamentos, com a forma de pagamento — cartão é por onde
  /// se paga, nunca o que se gastou.
  static const List<(String, String, int)> entries = [
    ('Mercado do bairro', 'débito · hoje', 8740),
    ('Padaria', 'Pix · hoje', 1250),
    ('Farmácia', 'Cartão Ipê · ontem', 3490),
    ('Feira de sábado', 'vale · sábado', 4600),
  ];

  /// Uma lista de linhas com o valor à direita.
  static Widget rows(List<(String, String, int)> items) {
    return CajuiCard(
      padding: const EdgeInsets.symmetric(
        horizontal: CajuiSpacing.lg,
        vertical: CajuiSpacing.sm,
      ),
      child: Column(
        children: [
          for (final (title, detail, cents) in items)
            CajuiListRow(
              title: title,
              subtitle: detail,
              trailing: CajuiAmountText(cents),
            ),
        ],
      ),
    );
  }

  /// A luz do fundo: um halo de cajuí e capim dourado no alto, que sobe
  /// mais devagar que a lista.
  static Widget backdrop(BuildContext context) {
    final brand = CajuiTheme.of(context).colors.brand;
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: 420,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.6, -1),
              radius: 1.1,
              colors: [
                brand.accent.withValues(alpha: 0.16),
                brand.gold.withValues(alpha: 0.07),
                brand.gold.withValues(alpha: 0),
              ],
              stops: const [0, 0.45, 1],
            ),
          ),
        ),
      ),
    );
  }

  /// O alto de uma tela: o mês e o título.
  static Widget heading(BuildContext context, String title) {
    final theme = CajuiTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OUTUBRO DE 2026',
            style: theme.typography.overline.copyWith(
              color: theme.colors.text.faint,
            ),
          ),
          Semantics(
            header: true,
            child: Text(
              title,
              style: theme.typography.headline.copyWith(
                color: theme.colors.text.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
