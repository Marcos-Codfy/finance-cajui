import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Um exemplar: o componente num estado, com o nome do estado por cima.
///
/// O nome vem escrito porque a gallery é também a lista de conferência: quem
/// revisa um componente lê os estados e vê se falta algum.
class GallerySpecimen extends StatelessWidget {
  /// Cria o exemplar do estado [state].
  const new({required this.state, required this.child, this.width, super.key});

  /// O nome do estado: "Repouso", "Carregando", "Com erro".
  final String state;

  /// O componente, já no estado.
  final Widget child;

  /// Largura fixa, para componente que ocupa a linha inteira (campo, aviso).
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            state,
            style: theme.typography.caption.copyWith(
              color: theme.colors.text.faint,
            ),
          ),
          const SizedBox(height: CajuiSpacing.sm),
          child,
        ],
      ),
    );
  }
}
