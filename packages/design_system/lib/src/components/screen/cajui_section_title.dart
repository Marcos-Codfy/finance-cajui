import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// O título de uma seção dentro de uma tela: "Contas fixas", "Por onde foi
/// pago".
///
/// Traz o próprio respiro — o espaço de seção acima, o pequeno abaixo — para
/// que duas telas nunca separem seções de jeitos diferentes. É anunciado como
/// cabeçalho, e o leitor de tela salta de seção em seção por ele.
class CajuiSectionTitle extends StatelessWidget {
  /// Cria o título [text].
  const new(this.text, {super.key});

  /// O nome da seção.
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        top: CajuiSpacing.section,
        bottom: CajuiSpacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Text(text, style: theme.typography.title),
      ),
    );
  }
}
