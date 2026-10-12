import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Um exemplar: o componente num estado, com o nome do estado por cima.
///
/// O nome vem escrito porque a gallery é também a lista de conferência: quem
/// revisa um componente lê os estados e vê se falta algum.
class GallerySpecimen extends StatelessWidget {
  /// Cria o exemplar do estado [state].
  const new({
    required this.state,
    required this.child,
    this.token,
    this.width,
    super.key,
  });

  /// O nome do estado, em português: "Repouso", "Carregando", "Principal".
  final String state;

  /// O nome do valor na API, quando o exemplar é um valor de enum ou de
  /// token: `primary`. Vem depois do nome, mais apagado — quem lê o código
  /// acha o valor, e quem só olha lê português.
  final String? token;

  /// O componente, já no estado.
  final Widget child;

  /// Largura fixa, para componente que ocupa a linha inteira (campo, aviso).
  /// Com ela, o componente estica até a largura: sem isso, um cartão
  /// encolhia dentro da caixa e os vãos entre exemplares ficavam tortos.
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: width == null
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _label(CajuiTheme.of(context)),
          const SizedBox(height: CajuiSpacing.sm),
          child,
        ],
      ),
    );
  }

  Widget _label(CajuiThemeData theme) {
    final style = theme.typography.caption;
    final api = token;
    return Text.rich(
      TextSpan(
        text: state,
        style: style.copyWith(color: theme.colors.text.muted),
        children: [
          if (api != null)
            TextSpan(
              text: '  $api',
              style: style.copyWith(color: theme.colors.text.faint),
            ),
        ],
      ),
    );
  }
}
