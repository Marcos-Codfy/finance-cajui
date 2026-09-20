import 'package:design_system/src/interaction/cajui_pressable.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_curves.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:design_system/src/tokens/primitives/cajui_radius.dart';
import 'package:design_system/src/tokens/semantic/cajui_colors.dart';
import 'package:flutter/widgets.dart';

/// A chave de liga e desliga: som, avisos, "fora do padrão".
///
/// Ligado e desligado diferem pela posição do botão, e não só pela cor. O
/// leitor de tela recebe o estado pela semântica de alternância.
class CajuiSwitch extends StatelessWidget {
  /// Cria uma chave. [semanticLabel] diz o que ela liga: "Sons do app".
  const new({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    super.key,
  });

  /// Se está ligada.
  final bool value;

  /// Chamado com o novo valor. `null` desabilita.
  final ValueChanged<bool>? onChanged;

  /// O que a chave controla, para o leitor de tela.
  final String semanticLabel;

  static const double _width = 52;
  static const double _height = 32;
  static const double _thumb = 24;
  static const _radius = BorderRadius.all(CajuiRadius.pill);

  @override
  Widget build(BuildContext context) {
    final callback = onChanged;
    return CajuiPressable(
      onPressed: callback == null ? null : () => callback(!value),
      toggled: value,
      radius: _radius,
      semanticLabel: semanticLabel,
      builder: _track,
    );
  }

  Widget _track(BuildContext context, Set<WidgetState> states) {
    final theme = CajuiTheme.of(context);
    final disabled = states.contains(WidgetState.disabled);
    final (track, thumb, outline) = _paint(theme.colors, disabled: disabled);
    return AnimatedContainer(
      duration: CajuiDurations.fast,
      width: _width,
      height: _height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: track,
        borderRadius: _radius,
        border: Border.all(color: outline),
      ),
      child: AnimatedAlign(
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        duration: theme.motionLevel.allowsSpring
            ? CajuiDurations.base
            : CajuiDurations.reducedFade,
        curve: CajuiCurves.spring,
        child: _knob(thumb),
      ),
    );
  }

  Widget _knob(Color color) {
    return SizedBox.square(
      dimension: _thumb,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }

  /// Trilho, botão e contorno. O botão tem sempre 3:1 contra o trilho:
  /// desligado, `text.muted` sobre `surface.sunken`; ligado, `text.onAction`
  /// sobre `action.primary`.
  (Color, Color, Color) _paint(CajuiColors c, {required bool disabled}) {
    if (disabled) {
      return (c.action.disabled, c.text.disabled, c.action.disabled);
    }
    if (value) {
      return (c.action.primary, c.text.onAction, c.action.primary);
    }
    return (c.surface.sunken, c.text.muted, c.border.field);
  }
}
