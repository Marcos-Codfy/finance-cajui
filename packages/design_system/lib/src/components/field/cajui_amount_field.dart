import 'package:design_system/src/components/button/cajui_button.dart';
import 'package:design_system/src/components/button/cajui_button_variant.dart';
import 'package:design_system/src/components/field/cajui_text_field.dart';
import 'package:design_system/src/components/field/cents_input_formatter.dart';
import 'package:design_system/src/format/brl_formatter.dart';
import 'package:design_system/src/icons/cajui_icon_data.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:flutter/widgets.dart';

/// O campo de valor em reais: o primeiro campo da tela de lançar.
///
/// Entrega centavos inteiros em [onChanged]. O valor é o maior elemento da
/// tela de lançamento, então o texto usa o estilo de valor em destaque.
class CajuiAmountField extends StatefulWidget {
  /// Cria um campo de valor começando em [initialCents].
  const new({
    required this.label,
    required this.onChanged,
    this.initialCents = 0,
    this.helper,
    this.error,
    this.enabled = true,
    super.key,
  });

  /// O nome do campo.
  final String label;

  /// Chamado com o valor em centavos a cada dígito.
  final ValueChanged<int> onChanged;

  /// O valor inicial, em centavos.
  final int initialCents;

  /// Texto de apoio: o efeito do valor, como "resta na semana: R$ 144,87".
  final String? helper;

  /// Mensagem de erro.
  final String? error;

  /// Se aceita entrada.
  final bool enabled;

  @override
  State<CajuiAmountField> createState() => _CajuiAmountFieldState();
}

class _CajuiAmountFieldState extends State<CajuiAmountField> {
  late final TextEditingController _controller = TextEditingController(
    text: BrlFormatter.number(widget.initialCents),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Começa outro valor para somar: "35,00 + ".
  void _add() {
    if (!_controller.text.trimRight().endsWith('+')) {
      final text = '${_controller.text} + ';
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    setState(() {});
  }

  Widget get _addButton => Align(
    alignment: Alignment.centerLeft,
    child: CajuiButton(
      label: 'Somar outro valor',
      icon: CajuiIconData.plus,
      variant: CajuiButtonVariant.ghost,
      onPressed: _add,
    ),
  );

  void _changed(String text) {
    setState(() {});
    widget.onChanged(CentsInputFormatter.parse(text));
  }

  @override
  Widget build(BuildContext context) {
    final terms = CentsInputFormatter.terms(_controller.text);
    final summing = terms.length > 1 || _controller.text.contains('+');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CajuiTextField(
          label: widget.label,
          controller: _controller,
          // Somando, a dica dá lugar ao total: "= R$ 47,00".
          helper: summing
              ? '= ${BrlFormatter.format(CentsInputFormatter.parse(_controller.text))}'
              : widget.helper,
          error: widget.error,
          enabled: widget.enabled,
          keyboardType: TextInputType.number,
          inputFormatters: const [CentsInputFormatter()],
          style: CajuiTheme.of(context).typography.amountLarge,
          onChanged: _changed,
        ),
        if (widget.enabled) _addButton,
      ],
    );
  }
}
