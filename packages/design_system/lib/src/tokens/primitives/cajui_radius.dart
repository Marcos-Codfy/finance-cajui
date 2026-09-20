import 'package:flutter/painting.dart';

/// Raios de canto. Generosos, porque repetem o gesto arredondado do símbolo:
/// nada no Cajui tem quina viva.
abstract final class CajuiRadius {
  /// 8 — marcador, selo pequeno.
  static const xs = Radius.circular(8);

  /// 12 — ícone com fundo, item de menu.
  static const sm = Radius.circular(12);

  /// 16 — campo, chip.
  static const md = Radius.circular(16);

  /// 20 — botão.
  static const lg = Radius.circular(20);

  /// 28 — cartão e folha.
  static const xl = Radius.circular(28);

  /// Cápsula: medidor, selo de confiança.
  static const pill = Radius.circular(999);
}
