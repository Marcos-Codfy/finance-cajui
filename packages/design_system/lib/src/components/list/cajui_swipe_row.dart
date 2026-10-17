import 'package:design_system/src/icons/cajui_icon.dart';
import 'package:design_system/src/icons/cajui_icon_data.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_radius.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// Uma linha que desliza: para a direita, [startLabel] (corrigir), e a
/// linha volta ao lugar; para a esquerda, [endLabel] (cancelar), e a linha
/// sai — quem usa decide o Desfazer. O leitor de tela ganha as duas como
/// ações da linha, porque deslizar ele não alcança.
class CajuiSwipeRow extends StatelessWidget {
  /// Cria a linha deslizável; [id] identifica a linha na lista.
  const new({
    required this.id,
    required this.child,
    required this.startLabel,
    required this.onStart,
    required this.endLabel,
    required this.onEnd,
    super.key,
  });

  /// O que identifica a linha: ela some da lista quando sai.
  final String id;

  /// A linha.
  final Widget child;

  /// O que deslizar para a direita faz: "Corrigir".
  final String startLabel;

  /// Chamado ao deslizar para a direita.
  final VoidCallback onStart;

  /// O que deslizar para a esquerda faz: "Cancelar".
  final String endLabel;

  /// Chamado quando a linha sai pela esquerda.
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) => Semantics(
    customSemanticsActions: {
      CustomSemanticsAction(label: startLabel): onStart,
      CustomSemanticsAction(label: endLabel): onEnd,
    },
    child: Dismissible(
      key: ValueKey('swipe-$id'),
      background: _side(
        context,
        startLabel,
        CajuiIconData.sliders,
        start: true,
      ),
      secondaryBackground: _side(
        context,
        endLabel,
        CajuiIconData.close,
        start: false,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) return true;
        onStart();
        return false;
      },
      onDismissed: (_) => onEnd(),
      child: child,
    ),
  );

  Widget _side(
    BuildContext context,
    String label,
    CajuiIconData icon, {
    required bool start,
  }) {
    final theme = CajuiTheme.of(context);
    final (fill, ink) = start
        ? (theme.colors.surface.sunken, theme.colors.text.primary)
        : (theme.colors.shortfall, theme.colors.text.onAction);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: const BorderRadius.all(CajuiRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: CajuiSpacing.xl),
        child: Row(
          mainAxisAlignment: start
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          spacing: CajuiSpacing.sm,
          children: [
            CajuiIcon(icon, color: ink),
            Text(label, style: theme.typography.label.copyWith(color: ink)),
          ],
        ),
      ),
    );
  }
}
