import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Um campo de texto da réplica, já com [text] escrito.
///
/// O `CajuiTextField` recebe o texto por um controlador, e controlador
/// criado no `build` vaza: este guarda o seu e o descarta com o campo.
class SampleTextField extends StatefulWidget {
  /// Cria o campo [label] com [text].
  const new({required this.label, required this.text, this.hint, super.key});

  /// O nome do campo.
  final String label;

  /// O que já está escrito.
  final String text;

  /// A dica, quando está vazio.
  final String? hint;

  @override
  State<SampleTextField> createState() => _SampleTextFieldState();
}

class _SampleTextFieldState extends State<SampleTextField> {
  late final TextEditingController _text = TextEditingController(
    text: widget.text,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      CajuiTextField(label: widget.label, hint: widget.hint, controller: _text);
}
