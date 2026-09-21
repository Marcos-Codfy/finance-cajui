import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// O rótulo de um campo, com o respiro que o separa do que ele nomeia.
///
/// Vale também para o que não é campo de texto: um grupo de escolhas sem
/// rótulo deixa quem usa leitor de tela sem saber o que está escolhendo. O
/// rótulo fica **sempre visível** — texto de exemplo que some ao digitar não
/// é rótulo.
class CajuiFieldLabel extends StatelessWidget {
  /// Cria o rótulo [text].
  const new(
    this.text, {
    this.enabled = true,
    this.excludeSemantics = false,
    super.key,
  });

  /// O nome do campo ou do grupo.
  final String text;

  /// Se o que ele nomeia aceita entrada.
  final bool enabled;

  /// Esconde o rótulo do leitor de tela. É o que a moldura de campo faz: lá
  /// o próprio campo já se anuncia com este nome, e repetir soaria duplicado.
  final bool excludeSemantics;

  /// O espaço entre o rótulo e o que ele nomeia.
  static const gap = SizedBox(height: CajuiSpacing.xs + CajuiSpacing.xxs);

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final label = Text(
      text,
      style: theme.typography.label.copyWith(
        color: enabled ? theme.colors.text.muted : theme.colors.text.disabled,
      ),
    );
    return excludeSemantics ? ExcludeSemantics(child: label) : label;
  }
}
