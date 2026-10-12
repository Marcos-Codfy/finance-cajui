import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/tokens/do_dont_pair.dart';
import 'package:gallery/src/shell/gallery_page.dart';

/// As regras próprias do Cajui, cada uma em par: o certo e o que evitar.
///
/// É o que separa este design system de um modelo pronto. As regras já
/// existiam espalhadas em descrições de seção; aqui cada uma tem o exemplo
/// lado a lado e o porquê numa frase.
class DoDontPage extends StatelessWidget {
  /// Cria a página.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Faça e evite',
      lead:
          'As regras próprias do Cajui, cada uma com o jeito certo e o que '
          'o app nunca faz, lado a lado.',
      sections: [
        _shortfall(),
        _card(),
        _voucher(),
        const DoDontPair(
          title: 'Cor nunca é o único sinal',
          why:
              'Quem não distingue cores precisa do ícone ou da palavra: o '
              'escolhido ganha o visto, e não só outra cor.',
          good: _ChosenChip(),
          bad: _ColorOnlyChip(),
        ),
      ],
    );
  }

  static Widget _shortfall() => const DoDontPair(
    title: 'A falta é fato, não bronca',
    why:
        'Quem se sente julgado para de olhar o app. A frase diz quanto falta '
        'e o que dá para fazer, no tom de barro.',
    good: CajuiNotice(
      what: r'Faltam R$ 120,00 para fechar outubro.',
      meaning: 'Dá para segurar o lazer até o fim do mês.',
    ),
    bad: _Scolding(),
  );

  static Widget _card() => DoDontPair(
    title: 'Cartão de crédito é forma de pagamento',
    why:
        'A despesa é a compra, na categoria dela; o cartão só diz como foi '
        'paga. Pagar a fatura não é gastar de novo.',
    good: _row('Mercado', 'Cartão Ipê · parcela 2 de 3', 8640),
    bad: _row('Cartão de crédito', 'Fatura de setembro', 25920),
  );

  static Widget _voucher() => DoDontPair(
    title: 'Vale-alimentação é outra moeda',
    why:
        'O vale só compra comida. Somado ao dinheiro, ele faz parecer que '
        'sobra para o aluguel.',
    good: Column(
      children: [
        _row('Entra em dinheiro', 'Salário', 420000),
        _row('Entra no vale', 'Só para comida', 60000),
      ],
    ),
    bad: _row('Entra no mês', 'Dinheiro e vale somados', 480000),
  );

  static Widget _row(String title, String subtitle, int cents) => CajuiListRow(
    title: title,
    subtitle: subtitle,
    trailing: CajuiAmountText(cents),
  );
}

/// O jeito de banco: vermelho, palavra técnica e exclamação.
class _Scolding extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final alarm = theme.colors.intent.danger;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          r'Déficit de R$ 120,00!',
          style: theme.typography.title.copyWith(color: alarm),
        ),
        Text(
          'Você estourou o orçamento de outubro.',
          style: theme.typography.caption.copyWith(color: alarm),
        ),
      ],
    );
  }
}

/// O chip do app: escolhido tem o visto.
class _ChosenChip extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: CajuiSpacing.sm,
      children: [
        CajuiChip(label: 'Mercado', selected: true, onSelected: (_) {}),
        CajuiChip(label: 'Lazer', selected: false, onSelected: (_) {}),
      ],
    );
  }
}

/// O mesmo par de chips só com cor: sem o visto, quem não vê a diferença de
/// cor não sabe qual está escolhido.
class _ColorOnlyChip extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    Widget pill(String label, {required bool on}) => DecoratedBox(
      decoration: BoxDecoration(
        color: on ? theme.colors.action.primary : theme.colors.surface.base,
        borderRadius: const BorderRadius.all(CajuiRadius.pill),
        border: Border.all(color: theme.colors.border.field),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CajuiSpacing.lg,
          vertical: CajuiSpacing.sm,
        ),
        child: Text(
          label,
          style: theme.typography.label.copyWith(
            color: on ? theme.colors.text.onAction : theme.colors.text.primary,
          ),
        ),
      ),
    );
    return Wrap(
      spacing: CajuiSpacing.sm,
      children: [pill('Mercado', on: true), pill('Lazer', on: false)],
    );
  }
}
