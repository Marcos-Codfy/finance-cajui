import 'package:design_system/src/tokens/semantic/action_colors.dart';
import 'package:design_system/src/tokens/semantic/border_colors.dart';
import 'package:design_system/src/tokens/semantic/brand_colors.dart';
import 'package:design_system/src/tokens/semantic/data_colors.dart';
import 'package:design_system/src/tokens/semantic/intent_colors.dart';
import 'package:design_system/src/tokens/semantic/shortfall_style.dart';
import 'package:design_system/src/tokens/semantic/surface_colors.dart';
import 'package:design_system/src/tokens/semantic/text_colors.dart';
import 'package:flutter/widgets.dart';

/// Todas as cores semânticas de um tema, agrupadas por papel.
///
/// É o que um componente recebe. Ele pede `colors.text.muted` ou
/// `colors.action.primary`; nunca um tom da paleta.
@immutable
class CajuiColors {
  /// Reúne os grupos de cor de um tema.
  const new({
    required this.brightness,
    required this.surface,
    required this.text,
    required this.action,
    required this.intent,
    required this.border,
    required this.brand,
    required this.data,
    this.shortfallStyle = ShortfallStyle.calm,
  });

  /// Tema claro.
  const new light({this.shortfallStyle = ShortfallStyle.calm})
    : brightness = Brightness.light,
      surface = SurfaceColors.light,
      text = TextColors.light,
      action = ActionColors.light,
      intent = IntentColors.light,
      border = BorderColors.light,
      brand = BrandColors.light,
      data = DataColors.light;

  /// Tema escuro.
  const new dark({this.shortfallStyle = ShortfallStyle.calm})
    : brightness = Brightness.dark,
      surface = SurfaceColors.dark,
      text = TextColors.dark,
      action = ActionColors.dark,
      intent = IntentColors.dark,
      border = BorderColors.dark,
      brand = BrandColors.dark,
      data = DataColors.dark;

  /// Claro ou escuro.
  final Brightness brightness;

  /// `surface.*`
  final SurfaceColors surface;

  /// `text.*`
  final TextColors text;

  /// `action.*`
  final ActionColors action;

  /// `intent.*`
  final IntentColors intent;

  /// `border.*` e `focus.*`
  final BorderColors border;

  /// `brand.*`
  final BrandColors brand;

  /// `data.*`
  final DataColors data;

  /// Qual das duas versões pinta a falta do mês.
  final ShortfallStyle shortfallStyle;

  /// A cor da falta do mês, da dívida e do limite ultrapassado.
  ///
  /// Fica num lugar só para a escolha entre barro e vermelho ser uma troca de
  /// valor, não uma caça a usos espalhados.
  Color get shortfall => switch (shortfallStyle) {
    ShortfallStyle.calm => intent.notice,
    ShortfallStyle.alarm => intent.danger,
  };

  /// O fundo sutil que acompanha [shortfall].
  Color get shortfallSubtle => switch (shortfallStyle) {
    ShortfallStyle.calm => intent.noticeSubtle,
    ShortfallStyle.alarm => intent.dangerSubtle,
  };
}
