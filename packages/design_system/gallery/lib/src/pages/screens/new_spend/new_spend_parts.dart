import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/shared/sample_text_field.dart';

/// As peças do "Novo gasto", como o app as desenha: os gastos de sempre, os
/// campos na ordem da lembrança (quanto, o quê, de que tipo, por onde,
/// quando) e o pé com o botão ou a pergunta do valor.
abstract final class NewSpendParts {
  static const _gap = SizedBox(height: CajuiSpacing.lg);

  /// Os gastos de sempre do exemplo, inventados.
  static const _habits = [
    ('Padaria Pão Quente', 1250),
    ('Mercado Boa Compra', 8600),
    ('Ônibus', 500),
  ];

  /// "Gastos de sempre", em chips.
  static List<Widget> habits(BuildContext context) =>
      _suggestions(context, 'Gastos de sempre', _habits);

  /// "Repetir o último", quando nada se repete.
  static List<Widget> repeatLast(BuildContext context) =>
      _suggestions(context, 'Repetir o último', const [('Farmácia', 3200)]);

  static List<Widget> _suggestions(
    BuildContext context,
    String title,
    List<(String, int)> items,
  ) {
    final theme = CajuiTheme.of(context);
    return [
      Text(
        title,
        style: theme.typography.label.copyWith(color: theme.colors.text.muted),
      ),
      const SizedBox(height: CajuiSpacing.sm),
      Wrap(
        spacing: CajuiSpacing.sm,
        runSpacing: CajuiSpacing.sm,
        children: [
          for (final (name, cents) in items)
            CajuiChip(
              label: '$name · ${BrlFormatter.format(cents)}',
              selected: false,
              onSelected: (_) {},
            ),
        ],
      ),
      _gap,
    ];
  }

  /// Os campos, com o que já foi preenchido, na ordem da lembrança.
  static List<Widget> fields({
    required int cents,
    required String description,
    String? category,
  }) => [
    ..._what(cents: cents, description: description, category: category),
    ..._how(),
    const SizedBox(height: CajuiSpacing.xxl),
  ];

  /// O "o quê": valor, descrição e categoria.
  static List<Widget> _what({
    required int cents,
    required String description,
    String? category,
  }) => [
    CajuiAmountField(
      key: ValueKey(('valor', cents)),
      label: 'Valor',
      initialCents: cents,
      onChanged: (_) {},
    ),
    _gap,
    SampleTextField(
      label: 'O que foi',
      text: description,
      hint: 'Mercado, ônibus, farmácia',
    ),
    _gap,
    CajuiSelectField(
      label: 'Categoria',
      value: category,
      helper: category == null
          ? 'Sem escolher, vai pelo nome do lugar — ou em Outros'
          : 'Entra nos gastos variáveis do mês',
      onPressed: () {},
    ),
    _gap,
  ];

  /// O "por onde" e o "quando".
  static List<Widget> _how() => [
    CajuiSelectField(
      label: 'Por onde foi pago',
      value: 'Pix',
      onPressed: () {},
    ),
    _gap,
    Wrap(
      spacing: CajuiSpacing.sm,
      runSpacing: CajuiSpacing.sm,
      children: [
        for (final (label, selected) in const [
          ('Hoje', true),
          ('Ontem', false),
          ('Outro dia', false),
        ])
          CajuiChip(label: label, selected: selected, onSelected: (_) {}),
      ],
    ),
  ];

  /// O botão de gravar, que diz o que falta quando falta.
  static Widget submit(String label, {bool enabled = true}) => CajuiButton(
    label: label,
    expand: true,
    onPressed: enabled ? () {} : null,
  );

  /// A pergunta do valor fora do comum, no lugar do botão.
  static Widget confirm({required String amount, required String typical}) =>
      CajuiNotice(
        what: 'Confere o valor: $amount?',
        meaning: 'Nessa categoria, o normal fica perto de $typical.',
        primaryAction: CajuiNoticeAction(
          label: 'Está certo, salvar',
          onPressed: () {},
        ),
        secondaryAction: CajuiNoticeAction(
          label: 'Corrigir o valor',
          onPressed: () {},
        ),
      );
}
