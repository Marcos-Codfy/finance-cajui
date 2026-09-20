import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Uma fileira de exemplares que quebra de linha quando a tela aperta.
class GallerySpecimens extends StatelessWidget {
  /// Cria a fileira com os exemplares [children].
  const new({required this.children, super.key});

  /// Os exemplares, na ordem.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: CajuiSpacing.xxl,
      runSpacing: CajuiSpacing.xxl,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: children,
    );
  }
}
