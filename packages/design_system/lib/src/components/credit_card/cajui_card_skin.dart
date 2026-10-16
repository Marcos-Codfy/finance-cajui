import 'dart:ui' show Color;

import 'package:design_system/src/tokens/primitives/cajui_cerrado_palette.dart';

/// A cor do plástico do cartão, escolhida pela pessoa no cadastro (pedido do
/// dono em 15/10/2026: "cores típicas do cerrado").
///
/// O app guarda só o [slug] — a palavra que viaja e fica no registro —, e o
/// design system decide a cor. [cajui] é o tom de ação do tema, o de sempre.
enum CajuiCardSkin {
  /// O laranja do Cajui, o tom de ação do tema.
  cajui('cajui', 'Cajuí', null, null),

  /// O âmbar do pequi.
  pequi(
    'pequi',
    'Pequi',
    CajuiCerradoPalette.pequiTop,
    CajuiCerradoPalette.pequiBottom,
  ),

  /// O mostarda do ipê-amarelo.
  ipeAmarelo(
    'ipe-amarelo',
    'Ipê-amarelo',
    CajuiCerradoPalette.ipeAmareloTop,
    CajuiCerradoPalette.ipeAmareloBottom,
  ),

  /// O rosa-arroxeado do ipê-roxo.
  ipeRoxo(
    'ipe-roxo',
    'Ipê-roxo',
    CajuiCerradoPalette.ipeRoxoTop,
    CajuiCerradoPalette.ipeRoxoBottom,
  ),

  /// O vinho do buriti.
  buriti(
    'buriti',
    'Buriti',
    CajuiCerradoPalette.buritiTop,
    CajuiCerradoPalette.buritiBottom,
  ),

  /// O verde-oliva da folha seca.
  folha(
    'folha',
    'Folha do cerrado',
    CajuiCerradoPalette.folhaTop,
    CajuiCerradoPalette.folhaBottom,
  ),

  /// O vermelho da terra.
  barro(
    'barro',
    'Barro',
    CajuiCerradoPalette.barroTop,
    CajuiCerradoPalette.barroBottom,
  ),

  /// O azul do céu de seca.
  ceu(
    'ceu',
    'Céu de seca',
    CajuiCerradoPalette.ceuTop,
    CajuiCerradoPalette.ceuBottom,
  );

  new(this.slug, this.label, this.top, this.bottom);

  /// A palavra que o app guarda.
  final String slug;

  /// O nome que a pessoa lê.
  final String label;

  /// O alto do gradiente; nulo no [cajui], que segue o tema.
  final Color? top;

  /// O baixo do gradiente; nulo no [cajui].
  final Color? bottom;

  /// O texto e o chip sobre o tom.
  static const Color ink = CajuiCerradoPalette.ink;

  /// O tom de [slug]; o de sempre quando não há ou não se conhece.
  static CajuiCardSkin of(String? slug) =>
      values.where((skin) => skin.slug == slug).firstOrNull ?? cajui;
}
