import 'package:design_system/src/accessibility/contrast_requirement.dart';
import 'package:design_system/src/accessibility/wcag_contrast.dart';
import 'package:flutter/widgets.dart';

/// Um par de cores que aparece junto numa tela, com o mínimo que ele precisa
/// cumprir.
@immutable
class ContrastPair {
  /// Declara que [foreground] é usado sobre [background].
  const new({
    required this.foregroundName,
    required this.backgroundName,
    required this.foreground,
    required this.background,
    required this.requirement,
  });

  /// O token da frente, como `text.muted`.
  final String foregroundName;

  /// O token do fundo, como `surface.sunken`.
  final String backgroundName;

  /// A cor da frente.
  final Color foreground;

  /// A cor do fundo.
  final Color background;

  /// O mínimo exigido para este uso.
  final ContrastRequirement requirement;

  /// A razão medida.
  double get ratio => WcagContrast.ratio(foreground, background);

  /// Se o par cumpre o mínimo.
  bool get passes => ratio >= requirement.minimum;

  @override
  String toString() =>
      '$foregroundName sobre $backgroundName: '
      '${ratio.toStringAsFixed(2)}:1 (mínimo ${requirement.minimum})';
}
