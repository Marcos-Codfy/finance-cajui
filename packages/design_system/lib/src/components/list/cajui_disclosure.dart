import 'package:design_system/src/icons/cajui_icon.dart';
import 'package:design_system/src/icons/cajui_icon_data.dart';
import 'package:design_system/src/interaction/cajui_pressable.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/theme/cajui_theme_data.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// Um "Mais" que abre e fecha: as portas de menos uso ficam guardadas sem
/// sumir. O leitor de tela ouve se está aberto.
class CajuiDisclosure extends StatefulWidget {
  /// Cria o "Mais" com [title], guardando [children].
  const new({required this.title, required this.children, super.key});

  /// O nome: "Mais".
  final String title;

  /// O que aparece aberto.
  final List<Widget> children;

  @override
  State<CajuiDisclosure> createState() => _CajuiDisclosureState();
}

class _CajuiDisclosureState extends State<CajuiDisclosure> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CajuiPressable(
          onPressed: () => setState(() => _open = !_open),
          semanticLabel: widget.title,
          toggled: _open,
          builder: (context, _) => _header(theme),
        ),
        if (_open) ...widget.children,
      ],
    );
  }

  /// O nome e a seta, que gira um quarto de volta ao abrir.
  Widget _header(CajuiThemeData theme) => Padding(
    padding: const EdgeInsets.symmetric(vertical: CajuiSpacing.md),
    child: Row(
      children: [
        Expanded(
          child: Text(
            widget.title,
            style: theme.typography.label.copyWith(
              color: theme.colors.text.muted,
            ),
          ),
        ),
        AnimatedRotation(
          turns: _open ? 0.25 : 0,
          duration: CajuiDurations.fast,
          child: const CajuiIcon(CajuiIconData.chevronRight),
        ),
      ],
    ),
  );
}
