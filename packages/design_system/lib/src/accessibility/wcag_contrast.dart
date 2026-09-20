import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// A conta de contraste da WCAG 2.2, pela luminância relativa.
///
/// Vive no pacote — e não só no teste — porque a gallery mostra a tabela de
/// contraste calculada ao vivo com os tokens em uso. Assim o número exibido
/// nunca fica desatualizado em relação à cor.
abstract final class WcagContrast {
  /// A razão de contraste entre duas cores, de 1 a 21.
  ///
  /// Se [foreground] tiver transparência, ele é composto sobre [background]
  /// antes da conta: é a cor que o olho de fato vê.
  static double ratio(Color foreground, Color background) {
    final visible = Color.alphaBlend(foreground, background);
    final a = _luminance(visible);
    final b = _luminance(background);
    final lighter = math.max(a, b);
    final darker = math.min(a, b);
    return (lighter + 0.05) / (darker + 0.05);
  }

  static double _luminance(Color color) {
    return 0.2126 * _linear(color.r) +
        0.7152 * _linear(color.g) +
        0.0722 * _linear(color.b);
  }

  static double _linear(double channel) {
    if (channel <= 0.04045) return channel / 12.92;
    return math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }
}
