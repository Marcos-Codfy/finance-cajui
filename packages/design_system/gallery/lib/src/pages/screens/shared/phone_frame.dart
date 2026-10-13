import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// A moldura de um aparelho: a tela aparece do tamanho em que vai existir,
/// e não esticada na largura do navegador.
///
/// É a moldura única da gallery — telas do app, palcos de movimento e
/// comparações. Antes eram três, de larguras, alturas e acabamentos
/// diferentes, e o "celular" mudava de página para página sem motivo.
class PhoneFrame extends StatelessWidget {
  /// Cria a moldura em volta de [child]; [height] nula deixa a tela do
  /// tamanho do conteúdo (um bloco só, como o carrossel).
  const new({required this.child, this.height = 780, super.key});

  /// A tela.
  final Widget child;

  /// A altura da tela.
  final double? height;

  /// A largura lógica de um Android médio. Em tela mais estreita que isso
  /// (um celular de 360 vendo a gallery), a moldura encolhe para caber.
  static const double width = 390;

  @override
  Widget build(BuildContext context) {
    final colors = CajuiTheme.of(context).colors;
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        width: math.min(width, constraints.maxWidth),
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.surface.base,
          borderRadius: const BorderRadius.all(CajuiRadius.xl),
          border: Border.all(color: colors.border.strong, width: 2),
          boxShadow: CajuiShadows.raised,
        ),
        child: child,
      ),
    );
  }
}
