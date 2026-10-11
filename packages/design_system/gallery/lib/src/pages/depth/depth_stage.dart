import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// O palco dos efeitos de profundidade: uma tela de celular de verdade, com
/// a própria rolagem.
///
/// Os efeitos dependem de onde o bloco está **na tela que rola** — sem uma
/// tela do tamanho de um aparelho, a borda que curva seria a da janela do
/// navegador. Em tela estreita, o palco encolhe para caber.
class DepthStage extends StatelessWidget {
  /// Monta o palco em volta de [child].
  const new({required this.child, this.height = 620, super.key});

  /// A tela.
  final Widget child;

  /// A altura do palco.
  final double height;

  /// A largura de um Android pequeno: o pior caso de leitura.
  static const double _width = 360;

  @override
  Widget build(BuildContext context) {
    final colors = CajuiTheme.of(context).colors;
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        width: math.min(_width, constraints.maxWidth),
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.surface.base,
          borderRadius: const BorderRadius.all(CajuiRadius.xl),
          border: Border.all(color: colors.border.strong, width: 2),
          boxShadow: CajuiShadows.floating,
        ),
        child: child,
      ),
    );
  }
}
