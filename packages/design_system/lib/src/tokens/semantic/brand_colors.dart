import 'package:design_system/src/tokens/primitives/cajui_palette.dart';
import 'package:flutter/widgets.dart';

/// Cores de marca para áreas grandes e ilustração: `brand.accent`,
/// `brand.gold`, o gradiente do fruto.
///
/// Nenhuma delas carrega texto pequeno: o cajuí puro dá 3,42:1 sobre a areia
/// e o capim dourado, 2,09:1. Para texto e botão, o caminho é `action.*`.
@immutable
class BrandColors {
  /// Cria o conjunto de cores de marca de um tema.
  const new({
    required this.accent,
    required this.gold,
    required this.fruitGradient,
    required this.sheen,
  });

  /// O laranja-cajuí. Um por tela.
  final Color accent;

  /// O capim dourado: conquista e deleite. É tempero, não base.
  final Color gold;

  /// As três paradas do gradiente do fruto, do topo à base.
  final List<Color> fruitGradient;

  /// A luz que bate numa superfície em 3D: o brilho do cartão, o reflexo do
  /// vidro do pote. É branca nos dois temas, porque luz não muda de cor
  /// quando a sala escurece — e entra sempre translúcida, nunca como fundo.
  final Color sheen;

  /// O mais forte que o brilho pode ficar por baixo de um texto.
  ///
  /// Luz clareia o fundo, e fundo mais claro tira contraste de texto branco:
  /// a 12%, o texto do cartão no tema claro fica em 4,58:1, ainda acima dos
  /// 4,5:1 da WCAG. O teste de contraste confere o par com o brilho aplicado.
  static const double sheenOverText = 0.12;

  static const List<Color> _fruit = [
    CajuiPalette.fruitTop,
    CajuiPalette.fruitMiddle,
    CajuiPalette.fruitBottom,
  ];

  /// Marca no tema claro.
  static const light = BrandColors(
    accent: CajuiPalette.cajui,
    gold: CajuiPalette.gold,
    fruitGradient: _fruit,
    sheen: CajuiPalette.paper,
  );

  /// Marca no tema escuro.
  static const dark = BrandColors(
    accent: CajuiPalette.cajuiLight,
    gold: CajuiPalette.goldLight,
    fruitGradient: _fruit,
    sheen: CajuiPalette.paper,
  );
}
