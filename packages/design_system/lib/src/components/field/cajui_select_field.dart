import 'package:design_system/src/components/field/cajui_field_frame.dart';
import 'package:design_system/src/icons/cajui_icon.dart';
import 'package:design_system/src/icons/cajui_icon_data.dart';
import 'package:design_system/src/interaction/cajui_pressable.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_radius.dart';
import 'package:flutter/widgets.dart';

/// O campo de escolha fechado: categoria, forma de pagamento, cartão.
///
/// Mostra o valor escolhido — ou nada. Na zona de confiança baixa a categoria
/// vem **vazia**, sem palpite (RN-796): por isso o estado vazio é um estado
/// de primeira classe, com texto próprio, e não um defeito a esconder.
///
/// Abrir a lista é de quem usa o campo; as opções vêm de `CajuiOptionList`.
class CajuiSelectField extends StatelessWidget {
  /// Cria o campo. [value] nulo é o estado vazio.
  const new({
    required this.label,
    required this.onPressed,
    this.value,
    this.placeholder = 'Escolher',
    this.helper,
    this.error,
    super.key,
  });

  /// O nome do campo.
  final String label;

  /// Abre a lista de opções. `null` desabilita.
  final VoidCallback? onPressed;

  /// O texto da opção escolhida.
  final String? value;

  /// O que aparece quando nada foi escolhido.
  final String placeholder;

  /// Texto de apoio.
  final String? helper;

  /// Mensagem de erro.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final chosen = value;
    return CajuiPressable(
      onPressed: onPressed,
      radius: const BorderRadius.all(CajuiRadius.md),
      semanticLabel: '$label: ${chosen ?? 'nada escolhido'}',
      builder: (context, states) => CajuiFieldFrame(
        label: label,
        helper: helper,
        error: error,
        enabled: onPressed != null,
        focused: states.contains(WidgetState.focused),
        hovered: states.contains(WidgetState.hovered),
        child: _content(context, chosen),
      ),
    );
  }

  Widget _content(BuildContext context, String? chosen) {
    final theme = CajuiTheme.of(context);
    final colors = theme.colors;
    final ink = chosen == null ? colors.text.faint : colors.text.primary;
    return Row(
      children: [
        Expanded(
          child: Text(
            chosen ?? placeholder,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.body.copyWith(color: ink),
          ),
        ),
        CajuiIcon(
          CajuiIconData.chevronRight,
          size: 20,
          color: colors.text.muted,
        ),
      ],
    );
  }
}
