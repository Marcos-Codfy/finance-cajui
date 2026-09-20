import 'package:flutter/widgets.dart';

/// A escala tipográfica: Fraunces dá a voz, Geist dá o dado.
///
/// Os estilos não carregam cor — quem pinta o texto é o componente, com um
/// token de `text.*`. Assim a mesma escala serve aos dois temas.
///
/// Regra de uso: a Fraunces aparece uma ou duas vezes por tela. Se tudo é
/// display, nada é.
@immutable
class CajuiTypography {
  /// A escala padrão da marca.
  const new();

  static const _package = 'design_system';

  /// 40/44 — o número-manchete do painel, em frase.
  TextStyle get displayLarge => _voice(size: 40, height: 44, weight: 520, tracking: -0.025);

  /// 32/36 — título de abertura de tela.
  TextStyle get displayMedium => _voice(size: 32, height: 36, weight: 520, tracking: -0.02);

  /// 24/30 — título de seção.
  TextStyle get headline => _voice(size: 24, height: 30, weight: 540, tracking: -0.015);

  /// 18/24 — título de cartão.
  TextStyle get title => _data(size: 18, height: 24, weight: 600, tracking: -0.005);

  /// 16/24 — corpo. É o piso de tamanho para texto corrido.
  TextStyle get body => _data(size: 16, height: 24, weight: 400);

  /// 16/24 — corpo com ênfase.
  TextStyle get bodyStrong => _data(size: 16, height: 24, weight: 600);

  /// 14/20 — rótulo de campo e de botão secundário.
  TextStyle get label => _data(size: 14, height: 20, weight: 500);

  /// 12,5/16 — legenda. Nada no app é menor que isto.
  TextStyle get caption => _data(size: 12.5, height: 16, weight: 400, tracking: 0.01);

  /// 12/16 em caixa alta — sobrelinha de seção. O chamador passa o texto já
  /// em maiúsculas; o estilo só abre o espaçamento.
  TextStyle get overline => _data(size: 12, height: 16, weight: 600, tracking: 0.12);

  /// 28/32 tabular — valor em destaque.
  TextStyle get amountLarge =>
      _data(size: 28, height: 32, weight: 600, tracking: -0.02, tabular: true);

  /// 16/24 tabular — valor em lista e tabela. Algarismos tabulares alinham
  /// casa com casa numa coluna de dinheiro.
  TextStyle get amount => _data(size: 16, height: 24, weight: 600, tabular: true);

  /// Fraunces com cantos macios (SOFT 100), sem formas excêntricas (WONK 0) e
  /// tamanho óptico igual ao tamanho de uso, que o Flutter não ajusta sozinho.
  TextStyle _voice({
    required double size,
    required double height,
    required double weight,
    required double tracking,
  }) {
    return TextStyle(
      fontFamily: 'Fraunces',
      package: _package,
      fontSize: size,
      height: height / size,
      letterSpacing: tracking * size,
      fontVariations: [
        FontVariation('wght', weight),
        FontVariation('opsz', size.clamp(9, 144)),
        const FontVariation('SOFT', 100),
        const FontVariation('WONK', 0),
      ],
    );
  }

  TextStyle _data({
    required double size,
    required double height,
    required double weight,
    double tracking = 0,
    bool tabular = false,
  }) {
    return TextStyle(
      fontFamily: 'Geist',
      package: _package,
      fontSize: size,
      height: height / size,
      letterSpacing: tracking * size,
      fontVariations: [FontVariation('wght', weight)],
      fontFeatures: [if (tabular) const FontFeature.tabularFigures()],
    );
  }
}
