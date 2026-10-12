import 'package:design_system/src/components/button/cajui_button.dart';
import 'package:design_system/src/components/button/cajui_button_size.dart';
import 'package:design_system/src/components/button/cajui_button_variant.dart';
import 'package:design_system/src/components/chip/cajui_chip.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/theme/cajui_theme_data.dart';
import 'package:design_system/src/tokens/primitives/cajui_radius.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// Uma linha da lista curta dentro da fala: o nome e o valor já escritos.
typedef CajuiPromptRow = ({String label, String value});

/// Um botão de resposta: o rótulo e o que acontece. O primeiro com
/// `primary` é o caminho que a fala espera.
typedef CajuiPromptAction = ({
  String label,
  VoidCallback? onPressed,
  bool primary,
});

/// Uma fala do assistente que pede resposta: o texto, uma lista curta
/// opcional e, embaixo, os botões ou as opções (RN-1113, RN-1114).
///
/// Existe porque a fala comum (`CajuiChatBubble`) esconde do leitor de tela
/// tudo o que estiver dentro dela — ela é lida inteira, uma vez. Aqui só o
/// texto e a lista ficam no balão; os botões e as opções ficam fora dele,
/// cada um com o seu nome, para quem usa leitor de tela poder responder.
class CajuiChatPrompt extends StatelessWidget {
  /// Cria a fala [text].
  const new(
    this.text, {
    this.speaker = 'Cajui',
    this.rows = const [],
    this.more,
    this.actions = const [],
    this.options = const [],
    this.onOption,
    super.key,
  });

  /// O que o assistente diz.
  final String text;

  /// O nome que o leitor de tela diz antes da fala.
  final String speaker;

  /// A lista curta: as compras de um bloco, as linhas de uma correção.
  final List<CajuiPromptRow> rows;

  /// O que ficou de fora da lista: "e mais 9".
  final String? more;

  /// Os botões de resposta. Vazio quando a fala já foi respondida.
  final List<CajuiPromptAction> actions;

  /// As opções, em chips: uma escolha só.
  final List<String> options;

  /// A opção escolhida.
  final ValueChanged<String>? onOption;

  static const double _maxWidth = 320;

  String get _spoken => [
    '$speaker: $text',
    for (final row in rows) '${row.label}, ${row.value}',
    ?more,
  ].join('. ');

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: _spoken,
            liveRegion: true,
            excludeSemantics: true,
            child: _balloon(theme),
          ),
          if (actions.isNotEmpty) _actions(),
          if (options.isNotEmpty) _options(),
        ],
      ),
    );
  }

  Widget _balloon(CajuiThemeData theme) {
    final colors = theme.colors;
    return Container(
      constraints: const BoxConstraints(maxWidth: _maxWidth),
      padding: const EdgeInsets.all(CajuiSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface.elevated,
        borderRadius: const BorderRadius.all(CajuiRadius.md),
        border: Border.all(color: colors.border.subtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: theme.typography.body.copyWith(color: colors.text.primary),
          ),
          if (rows.isNotEmpty) const SizedBox(height: CajuiSpacing.sm),
          for (final row in rows) _row(theme, row),
          if (more case final rest?) _rest(theme, rest),
        ],
      ),
    );
  }

  Widget _rest(CajuiThemeData theme, String rest) => Text(
    rest,
    style: theme.typography.caption.copyWith(color: theme.colors.text.muted),
  );

  /// O nome encolhe com reticências; o valor nunca: é ele que se confere.
  Widget _row(CajuiThemeData theme, CajuiPromptRow row) {
    final style = theme.typography.caption.copyWith(
      color: theme.colors.text.primary,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.label,
              style: style,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: CajuiSpacing.sm),
          Text(
            row.value,
            style: theme.typography.label.copyWith(
              color: theme.colors.text.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() => Padding(
    padding: const EdgeInsets.only(top: CajuiSpacing.sm),
    child: Wrap(
      spacing: CajuiSpacing.sm,
      runSpacing: CajuiSpacing.sm,
      children: [
        for (final action in actions)
          CajuiButton(
            label: action.label,
            onPressed: action.onPressed,
            size: CajuiButtonSize.compact,
            variant: action.primary
                ? CajuiButtonVariant.primary
                : CajuiButtonVariant.secondary,
          ),
      ],
    ),
  );

  Widget _options() => Padding(
    padding: const EdgeInsets.only(top: CajuiSpacing.sm),
    child: Wrap(
      spacing: CajuiSpacing.sm,
      runSpacing: CajuiSpacing.sm,
      children: [
        for (final option in options)
          CajuiChip(
            label: option,
            selected: false,
            onSelected: onOption == null ? null : (_) => onOption!(option),
          ),
      ],
    ),
  );
}
