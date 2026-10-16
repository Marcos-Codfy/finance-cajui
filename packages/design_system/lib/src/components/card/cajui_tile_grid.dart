import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// As portas de destaque em duas colunas, cada par da mesma altura — o
/// ladrilho de frase curta não fica menor que o vizinho de frase longa.
class CajuiTileGrid extends StatelessWidget {
  /// Arruma [children] de dois em dois.
  const new({required this.children, super.key});

  /// As portas, em geral `CajuiTile`.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    spacing: CajuiSpacing.md,
    children: [
      for (var at = 0; at < children.length; at += 2)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CajuiSpacing.md,
            children: [
              Expanded(child: children[at]),
              Expanded(
                child: at + 1 < children.length
                    ? children[at + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
    ],
  );
}
