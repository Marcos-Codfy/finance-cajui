import 'package:design_system/src/components/field/cajui_field_frame.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:flutter/material.dart'
    show InputDecoration, Material, MaterialType, TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// O campo de texto do Cajui.
///
/// Por dentro usa o campo do Material, sem a aparência dele: edição de texto
/// — seleção, área de transferência, teclado virtual, leitor de tela — é o
/// tipo de coisa que se perde ao refazer do zero. Por fora, tudo vem dos
/// tokens, pela [CajuiFieldFrame].
///
/// Estados: repouso, sob o cursor, com foco, desabilitado e com erro.
class CajuiTextField extends StatefulWidget {
  /// Cria um campo com o rótulo [label].
  const new({
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.error,
    this.enabled = true,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.style,
    this.textAlign = TextAlign.start,
    super.key,
  });

  /// O nome do campo, sempre visível.
  final String label;

  /// Controla o texto. Sem ele, o campo cria o próprio.
  final TextEditingController? controller;

  /// Exemplo de preenchimento. Não substitui o rótulo.
  final String? hint;

  /// Texto de apoio.
  final String? helper;

  /// Mensagem de erro; presente, põe o campo no estado de erro.
  final String? error;

  /// Se aceita entrada.
  final bool enabled;

  /// Chamado a cada mudança do texto.
  final ValueChanged<String>? onChanged;

  /// O teclado virtual pedido.
  final TextInputType? keyboardType;

  /// Filtros e máscaras aplicados ao que é digitado.
  final List<TextInputFormatter>? inputFormatters;

  /// O estilo do texto digitado. Por padrão, `body`.
  final TextStyle? style;

  /// O alinhamento do texto digitado.
  final TextAlign textAlign;

  @override
  State<CajuiTextField> createState() => _CajuiTextFieldState();
}

class _CajuiTextFieldState extends State<CajuiTextField> {
  final FocusNode _focus = FocusNode();
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: CajuiFieldFrame(
        label: widget.label,
        helper: widget.helper,
        error: widget.error,
        focused: _focus.hasFocus,
        hovered: _hovered,
        enabled: widget.enabled,
        child: Semantics(label: widget.label, child: _input(context)),
      ),
    );
  }

  Widget _input(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final colors = theme.colors;
    final base = widget.style ?? theme.typography.body;
    final ink = widget.enabled ? colors.text.primary : colors.text.disabled;
    return Material(
      type: MaterialType.transparency,
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        textAlign: widget.textAlign,
        style: base.copyWith(color: ink),
        cursorColor: colors.action.primary,
        decoration: InputDecoration.collapsed(
          hintText: widget.hint,
          hintStyle: base.copyWith(color: colors.text.faint),
        ),
      ),
    );
  }
}
