import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/theme/cajui_theme_data.dart';
import 'package:design_system/src/tokens/primitives/cajui_radius.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// O painel em si: alça, título e o conteúdo rolando, preso ao pé da tela
/// e com no máximo quatro quintos dela — sempre sobra a tela de trás à
/// vista, para ninguém se perder.
class CajuiSheet extends StatelessWidget {
  /// Cria o painel [title] com [children].
  const new({required this.title, required this.children, super.key});

  /// O título: "Categoria".
  final String title;

  /// O conteúdo, em geral uma lista de opções.
  final List<Widget> children;

  static const double _handleWidth = 36;
  static const double _handleHeight = 4;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final colors = theme.colors;
    final height = MediaQuery.sizeOf(context).height;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height * 0.8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface.elevated,
            borderRadius: const BorderRadius.vertical(top: CajuiRadius.xl),
          ),
          child: SafeArea(top: false, child: _body(theme)),
        ),
      ),
    );
  }

  Widget _body(CajuiThemeData theme) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: CajuiSpacing.sm),
      Center(child: _handle(theme)),
      _title(theme),
      Flexible(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: CajuiSpacing.xl),
          children: children,
        ),
      ),
    ],
  );

  Widget _title(CajuiThemeData theme) => Padding(
    padding: const EdgeInsets.fromLTRB(
      CajuiSpacing.xl,
      CajuiSpacing.lg,
      CajuiSpacing.xl,
      CajuiSpacing.sm,
    ),
    child: Semantics(
      header: true,
      child: Text(
        title,
        style: theme.typography.title.copyWith(
          color: theme.colors.text.primary,
        ),
      ),
    ),
  );

  Widget _handle(CajuiThemeData theme) => Container(
    width: _handleWidth,
    height: _handleHeight,
    decoration: BoxDecoration(
      color: theme.colors.border.strong,
      borderRadius: const BorderRadius.all(Radius.circular(_handleHeight)),
    ),
  );
}
