import 'package:design_system/src/motion/motion_level.dart';
import 'package:design_system/src/tokens/semantic/cajui_colors.dart';
import 'package:design_system/src/tokens/semantic/shortfall_style.dart';
import 'package:design_system/src/typography/cajui_typography.dart';
import 'package:flutter/widgets.dart';

/// Tudo o que um componente precisa saber sobre a aparência em vigor: cores,
/// tipografia e nível de movimento.
@immutable
class CajuiThemeData {
  /// Monta um tema a partir de suas partes.
  const new({
    required this.colors,
    this.typography = const CajuiTypography(),
    this.motionLevel = MotionLevel.full,
  });

  /// O tema claro da marca.
  ///
  /// Não é `const` porque repassa [shortfallStyle] às cores, e o Dart não
  /// aceita isso num construtor constante.
  new light({
    ShortfallStyle shortfallStyle = ShortfallStyle.calm,
    this.motionLevel = MotionLevel.full,
  }) : colors = CajuiColors.light(shortfallStyle: shortfallStyle),
       typography = const CajuiTypography();

  /// O tema escuro da marca: azul-petróleo, não o claro invertido.
  new dark({
    ShortfallStyle shortfallStyle = ShortfallStyle.calm,
    this.motionLevel = MotionLevel.full,
  }) : colors = CajuiColors.dark(shortfallStyle: shortfallStyle),
       typography = const CajuiTypography();

  /// As cores semânticas.
  final CajuiColors colors;

  /// A escala tipográfica.
  final CajuiTypography typography;

  /// Quanto de movimento está liberado.
  final MotionLevel motionLevel;

  /// Devolve o mesmo tema com outro nível de movimento.
  CajuiThemeData withMotionLevel(MotionLevel level) => CajuiThemeData(
    colors: colors,
    typography: typography,
    motionLevel: level,
  );

  @override
  bool operator ==(Object other) =>
      other is CajuiThemeData &&
      other.colors.brightness == colors.brightness &&
      other.colors.shortfallStyle == colors.shortfallStyle &&
      other.motionLevel == motionLevel;

  @override
  int get hashCode =>
      Object.hash(colors.brightness, colors.shortfallStyle, motionLevel);
}
