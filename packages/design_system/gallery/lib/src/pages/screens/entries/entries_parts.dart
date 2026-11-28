import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/shared/sample_text_field.dart';

/// Um lançamento do exemplo, inventado: o que foi, de que grupo, por onde
/// saiu, quando e quanto.
typedef SampleEntry = ({
  String description,
  String category,
  String paidWith,
  String day,
  int cents,
  CajuiIconData icon,
});

/// As peças da tela de Lançamentos, como o app as desenha: o mês com as
/// setas, o resumo do que já foi gasto, a lupa com os filtros, as linhas e
/// o rodapé de lançar.
abstract final class EntriesParts {
  /// O que a lista do exemplo traz, do mais recente ao mais antigo.
  static const List<SampleEntry> month = [
    (
      description: 'Padaria Pão Quente',
      category: 'Padaria',
      paidWith: 'Pix',
      day: 'hoje',
      cents: 1250,
      icon: CajuiIconData.wallet,
    ),
    (
      description: 'Mercado Boa Compra',
      category: 'Mercado',
      paidWith: 'Vale alimentação + Pix',
      day: 'ontem',
      cents: 8600,
      icon: CajuiIconData.wallet,
    ),
    (
      description: 'Uber',
      category: 'Transporte',
      paidWith: 'Cartão roxo',
      day: 'qua., 16 de set.',
      cents: 2390,
      icon: CajuiIconData.wallet,
    ),
    (
      description: 'Internet',
      category: 'Internet',
      paidWith: 'Boleto',
      day: 'seg., 14 de set.',
      cents: 9990,
      icon: CajuiIconData.calendar,
    ),
  ];

  /// O mês à vista, com as setas: não há mês depois do de hoje.
  static Widget stepper(BuildContext context, String month) {
    final theme = CajuiTheme.of(context);
    return Row(
      children: [
        CajuiIconButton(
          icon: CajuiIconData.chevronLeft,
          semanticLabel: 'Mês anterior',
          onPressed: () {},
        ),
        Expanded(
          child: Text(
            month,
            textAlign: TextAlign.center,
            style: theme.typography.title.copyWith(
              color: theme.colors.text.primary,
            ),
          ),
        ),
        const CajuiIconButton(
          icon: CajuiIconData.chevronRight,
          semanticLabel: 'Próximo mês',
          onPressed: null,
        ),
      ],
    );
  }

  /// O já gasto, uma linha por moeda: dinheiro e vale nunca se somam.
  static Widget spent(
    BuildContext context, {
    required int cash,
    int voucher = 0,
  }) => CajuiCard(
    sunken: true,
    padding: const EdgeInsets.symmetric(
      horizontal: CajuiSpacing.lg,
      vertical: CajuiSpacing.md,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _line(context, 'Já gasto em dinheiro', cash),
        const SizedBox(height: CajuiSpacing.xs),
        _line(context, 'Já gasto no vale alimentação', voucher),
        CajuiDisclosure(
          title: 'O que é cada número?',
          children: [_explanation(context)],
        ),
      ],
    ),
  );

  /// Por que este número não é o "Gastos do mês" do Painel.
  static Widget _explanation(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Text(
      'Aqui está o que já foi lançado neste mês. No Painel, "Gastos do mês" '
      'é o previsto para o mês todo. O vale alimentação é outra moeda e '
      'nunca se soma ao dinheiro.',
      style: theme.typography.caption.copyWith(color: theme.colors.text.muted),
    );
  }

  static Widget _line(BuildContext context, String label, int cents) {
    final theme = CajuiTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.typography.body.copyWith(
              color: theme.colors.text.muted,
            ),
          ),
        ),
        CajuiAmountText(cents),
      ],
    );
  }

  /// A lupa fechada e os filtros ao lado; [on] é o atalho ligado.
  static Widget filters({String? on}) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CajuiIconButton(
        icon: CajuiIconData.search,
        caption: 'Buscar',
        semanticLabel: 'Buscar nos lançamentos',
        variant: CajuiButtonVariant.secondary,
        onPressed: () {},
      ),
      const SizedBox(width: CajuiSpacing.md),
      Expanded(child: chips(on: on)),
    ],
  );

  /// A busca aberta com [text], o fechar ao lado e os filtros embaixo.
  static Widget search(String text) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: SampleTextField(
              label: 'Buscar',
              text: text,
              hint: 'Mercado, padaria, farmácia…',
            ),
          ),
          const SizedBox(width: CajuiSpacing.sm),
          CajuiIconButton(
            icon: CajuiIconData.close,
            semanticLabel: 'Fechar a busca',
            onPressed: () {},
          ),
        ],
      ),
      const SizedBox(height: CajuiSpacing.md),
      chips(text: text),
    ],
  );

  /// Os chips: categoria e forma de pagamento para escolher, e os atalhos
  /// de um toque. A busca em vigor também vira chip, e o toque a tira.
  static Widget chips({String? on, String? text}) => Wrap(
    spacing: CajuiSpacing.sm,
    runSpacing: CajuiSpacing.sm,
    children: [
      if (text != null) _chip('“$text”', selected: true),
      _chip('Categoria'),
      _chip('Forma de pagamento'),
      for (final shortcut in const [
        'Só vale alimentação',
        'Só cartão',
        'Esta semana',
      ])
        _chip(shortcut, selected: shortcut == on),
    ],
  );

  static Widget _chip(String label, {bool selected = false}) =>
      CajuiChip(label: label, selected: selected, onSelected: (_) {});

  /// As linhas de [entries], com o dia de cada uma no subtítulo.
  static List<Widget> rows(List<SampleEntry> entries) => [
    for (final entry in entries)
      CajuiListRow(
        leading: CajuiIcon(entry.icon, size: 20),
        title: entry.description,
        subtitle: '${entry.category} · ${entry.paidWith} · ${entry.day}',
        trailing: CajuiAmountText(entry.cents),
        semanticLabel:
            '${entry.description}, ${BrlFormatter.format(entry.cents)}, '
            '${entry.category}, ${entry.paidWith}, ${entry.day}, abrir',
        onPressed: () {},
      ),
  ];

  /// O rodapé numa linha: "Gastei" e, ao lado, a foto e a galeria.
  static Widget footer() => Row(
    children: [
      Expanded(
        child: CajuiButton(
          label: 'Gastei',
          icon: CajuiIconData.plus,
          expand: true,
          onPressed: () {},
        ),
      ),
      for (final (caption, icon) in const [
        ('Foto', CajuiIconData.camera),
        ('Galeria', CajuiIconData.image),
      ])
        Padding(
          padding: const EdgeInsets.only(left: CajuiSpacing.sm),
          child: CajuiIconButton(
            icon: icon,
            caption: caption,
            semanticLabel: caption,
            variant: CajuiButtonVariant.secondary,
            onPressed: () {},
          ),
        ),
    ],
  );
}
