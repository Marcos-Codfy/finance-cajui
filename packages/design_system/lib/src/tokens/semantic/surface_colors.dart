import 'package:design_system/src/tokens/primitives/cajui_palette.dart';
import 'package:flutter/widgets.dart';

/// Cores de superfície: `surface.base`, `surface.elevated`…
///
/// No claro a elevação é dita por sombra; no escuro, por superfície mais
/// clara. Por isso os dois temas têm valores próprios, e nenhum é o outro
/// invertido.
@immutable
class SurfaceColors {
  /// Cria o conjunto de superfícies de um tema.
  const new({
    required this.base,
    required this.sunken,
    required this.elevated,
    required this.high,
    required this.scrim,
  });

  /// Fundo da tela.
  final Color base;

  /// Área rebaixada: seção, campo, chip em repouso.
  final Color sunken;

  /// Cartão.
  final Color elevated;

  /// Folha inferior, menu, diálogo.
  final Color high;

  /// Véu que escurece o fundo atrás de folha e diálogo.
  final Color scrim;

  /// Superfícies do tema claro.
  static const light = SurfaceColors(
    base: CajuiPalette.sand,
    sunken: CajuiPalette.sandDeep,
    elevated: CajuiPalette.paper,
    high: CajuiPalette.paper,
    scrim: Color(0x732A1D17),
  );

  /// Superfícies do tema escuro.
  static const dark = SurfaceColors(
    base: CajuiPalette.night,
    sunken: CajuiPalette.nightDeep,
    elevated: CajuiPalette.nightRaised,
    high: CajuiPalette.nightHigh,
    scrim: Color(0x99000000),
  );
}
