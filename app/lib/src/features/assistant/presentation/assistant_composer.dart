import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// O campo de pergunta, com o botão de enviar ao lado.
///
/// Enquanto a resposta não chega, o campo espera: uma pergunta por vez.
class AssistantComposer extends StatefulWidget {
  /// Cria o campo. [onSend] recebe a pergunta.
  const new({required this.onSend, this.enabled = true, super.key});

  /// Chamado com a pergunta enviada.
  final ValueChanged<String> onSend;

  /// Se dá para perguntar agora.
  final bool enabled;

  /// O teto da pergunta, o mesmo do servidor (RN-952).
  static const maxLength = 1000;

  @override
  State<AssistantComposer> createState() => _AssistantComposerState();
}

class _AssistantComposerState extends State<AssistantComposer> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() {
    final question = _text.text.trim();
    if (question.isEmpty) return;
    widget.onSend(
      question.length > AssistantComposer.maxLength
          ? question.substring(0, AssistantComposer.maxLength)
          : question,
    );
    _text.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final canSend = widget.enabled && _text.text.trim().isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: CajuiTextField(
            label: 'Sua pergunta',
            hint: 'Quanto dá para gastar nesta semana?',
            controller: _text,
            enabled: widget.enabled,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: CajuiSpacing.sm),
        CajuiIconButton(
          icon: CajuiIconData.chevronRight,
          semanticLabel: 'Enviar pergunta',
          variant: CajuiButtonVariant.primary,
          onPressed: canSend ? _send : null,
        ),
      ],
    );
  }
}
