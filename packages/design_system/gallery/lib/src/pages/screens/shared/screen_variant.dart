import 'package:flutter/widgets.dart';

/// Um estado de uma tela: o nome no seletor, de onde ele vem na especificação
/// e como a tela fica.
class ScreenVariant {
  /// Cria o estado [label], explicado por [note] e desenhado por [builder].
  const new({
    required this.label,
    required this.note,
    required this.builder,
    this.moving = false,
  });

  /// O nome do estado no seletor: "Sem rede".
  final String label;

  /// Quando o estado acontece e que regra ou código o define.
  final String note;

  /// A tela neste estado.
  final WidgetBuilder builder;

  /// Se a diferença deste estado está no movimento — a festa do primeiro
  /// mês no verde. Parada, na miniatura, a tela é igual à do estado
  /// vizinho; a vitrine põe um selo para não parecer repetida.
  final bool moving;
}
