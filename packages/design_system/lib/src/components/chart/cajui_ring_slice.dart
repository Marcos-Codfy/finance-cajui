import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

/// Uma fatia do anel: o nome, o valor e a cor do grupo.
@immutable
class CajuiRingSlice {
  /// Cria a fatia [label] de [cents] centavos, na cor [color].
  const new({required this.label, required this.cents, required this.color});

  /// O nome: "Contas fixas".
  final String label;

  /// O valor, em centavos; zero ou menos não desenha fatia.
  final int cents;

  /// A cor do grupo, dos tokens de dados.
  final Color color;
}
