import 'package:design_system/src/tokens/primitives/cajui_palette.dart';
import 'package:flutter/widgets.dart';

/// Cores de contorno e de foco: `border.subtle`, `border.field`, `focus.ring`.
///
/// O anel de foco é desenhado **afastado** do controle, com uma folga na cor
/// da superfície entre os dois. Sem a folga, o anel "céu" encostaria no botão
/// "cajuí forte" com 1,01:1 de contraste e sumiria (BL-016, WCAG 2.4.7).
@immutable
class BorderColors {
  /// Cria o conjunto de contornos de um tema.
  const new({
    required this.subtle,
    required this.field,
    required this.strong,
    required this.focusRing,
    required this.focusGap,
  });

  /// Fio decorativo de cartão. Não carrega informação.
  final Color subtle;

  /// Contorno de campo: 3:1 contra toda superfície onde um campo aparece.
  final Color field;

  /// Contorno de destaque: campo com foco, item selecionado.
  final Color strong;

  /// O anel de foco do teclado.
  final Color focusRing;

  /// A folga entre o controle e o anel, na cor da superfície.
  final Color focusGap;

  /// Contornos do tema claro.
  static const light = BorderColors(
    subtle: Color(0x142A1D17),
    field: CajuiPalette.inkOutline,
    strong: CajuiPalette.ink,
    focusRing: CajuiPalette.sky,
    focusGap: CajuiPalette.sand,
  );

  /// Contornos do tema escuro.
  static const dark = BorderColors(
    subtle: Color(0x14F4ECE0),
    field: CajuiPalette.moonOutline,
    strong: CajuiPalette.moon,
    focusRing: CajuiPalette.skyLight,
    focusGap: CajuiPalette.night,
  );
}
