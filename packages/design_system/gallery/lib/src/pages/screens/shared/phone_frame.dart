import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// A moldura de um aparelho: a tela de estado aparece do tamanho em que vai
/// existir, e não esticada na largura do navegador.
class PhoneFrame extends StatelessWidget {
  /// Cria a moldura em volta de [child].
  const new({required this.child, super.key});

  /// A tela.
  final Widget child;

  /// Tamanho lógico de um aparelho Android médio.
  static const Size _screen = Size(390, 780);

  @override
  Widget build(BuildContext context) {
    final colors = CajuiTheme.of(context).colors;
    return Container(
      width: _screen.width,
      height: _screen.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface.base,
        borderRadius: const BorderRadius.all(CajuiRadius.xl),
        border: Border.all(color: colors.border.strong, width: 2),
      ),
      child: child,
    );
  }
}
