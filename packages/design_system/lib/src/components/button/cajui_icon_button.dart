import 'package:design_system/src/components/button/cajui_button_tokens.dart';
import 'package:design_system/src/components/button/cajui_button_variant.dart';
import 'package:design_system/src/icons/cajui_icon.dart';
import 'package:design_system/src/icons/cajui_icon_data.dart';
import 'package:design_system/src/interaction/cajui_pressable.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:design_system/src/tokens/primitives/cajui_radius.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// Um botão só de ícone: fechar, compartilhar, ligar o som.
///
/// Como não há texto visível, [semanticLabel] é obrigatório — é a única forma
/// de o leitor de tela dizer o que o botão faz (RNF-A11Y-06).
class CajuiIconButton extends StatelessWidget {
  /// Cria um botão de ícone.
  const new({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.variant = CajuiButtonVariant.ghost,
    super.key,
  });

  /// O ícone.
  final CajuiIconData icon;

  /// O que o botão faz, para o leitor de tela.
  final String semanticLabel;

  /// O que acontece ao ativar. `null` desabilita.
  final VoidCallback? onPressed;

  /// O peso do botão. Por padrão é discreto.
  final CajuiButtonVariant variant;

  static const _radius = BorderRadius.all(CajuiRadius.md);

  @override
  Widget build(BuildContext context) {
    return CajuiPressable(
      onPressed: onPressed,
      radius: _radius,
      semanticLabel: semanticLabel,
      builder: (context, states) {
        final colors = CajuiTheme.of(context).colors;
        final tokens = CajuiButtonTokens.resolve(colors, variant, states);
        return AnimatedContainer(
          duration: CajuiDurations.fast,
          width: CajuiSpacing.touchTarget,
          height: CajuiSpacing.touchTarget,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tokens.background,
            borderRadius: _radius,
          ),
          child: CajuiIcon(icon, color: tokens.foreground),
        );
      },
    );
  }
}
