import 'package:flutter/painting.dart';

/// Sombras por nível de elevação. A sombra é tingida de castanha, nunca preta:
/// preto puro suja as superfícies quentes da marca.
///
/// No tema escuro a sombra quase não se vê; lá a elevação é dita pela cor da
/// superfície (`surface.elevated`, `surface.high`), e estas listas ficam leves.
abstract final class CajuiShadows {
  static const _ink = Color(0xFF2A1D17);

  /// Sem elevação.
  static const List<BoxShadow> none = [];

  /// Cartão em repouso.
  static const List<BoxShadow> raised = [
    BoxShadow(color: Color(0x0F2A1D17), blurRadius: 12, offset: Offset(0, 4)),
  ];

  /// Cartão sob o cursor, botão flutuante.
  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x1F2A1D17), blurRadius: 28, offset: Offset(0, 12)),
  ];

  /// Folha inferior e diálogo.
  static const List<BoxShadow> overlay = [
    BoxShadow(color: Color(0x332A1D17), blurRadius: 48, offset: Offset(0, 20)),
  ];

  /// Sombra de contato dos ícones-herói em 3D, a cerca de 28%.
  static final List<BoxShadow> contact = [
    BoxShadow(
      color: _ink.withValues(alpha: 0.28),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];
}
