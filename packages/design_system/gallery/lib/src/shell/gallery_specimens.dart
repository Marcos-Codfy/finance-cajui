import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Uma fileira de exemplares que quebra de linha quando a tela aperta.
///
/// Alinhada pelo topo, que é o padrão do `Wrap`: os nomes dos estados ficam
/// todos na mesma altura. Pela base, como era, o exemplar mais baixo ficava
/// solto, com um vão em cima, e os nomes desencontrados davam à página a
/// cara de bagunça.
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
      children: children,
    );
  }
}
