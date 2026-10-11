import 'dart:async';

import 'package:cajui/src/features/assistant/application/speech_input.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O campo de pergunta, com o botão de enviar ao lado.
///
/// Enquanto a resposta não chega, o campo espera: uma pergunta por vez.
class AssistantComposer extends ConsumerStatefulWidget {
  /// Cria o campo. [onSend] recebe a pergunta.
  const new({
    required this.onSend,
    this.enabled = true,
    this.onFocused,
    super.key,
  });

  /// Chamado com a pergunta enviada.
  final ValueChanged<String> onSend;

  /// Se dá para perguntar agora.
  final bool enabled;

  /// Chamado quando o campo ganha o foco — e, com ele, o teclado sobe e a
  /// conversa encolhe. Quem está escrevendo quer ver o fim dela.
  final VoidCallback? onFocused;

  /// O teto da pergunta, o mesmo do servidor (RN-952).
  static const maxLength = 1000;

  @override
  ConsumerState<AssistantComposer> createState() => _AssistantComposerState();
}

class _AssistantComposerState extends ConsumerState<AssistantComposer> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  bool _canDictate = false;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
    unawaited(_askIfCanDictate());
  }

  Future<void> _askIfCanDictate() async {
    final can = await ref.read(speechInputProvider).isAvailable();
    if (mounted) setState(() => _canDictate = can);
  }

  /// Ouve e **põe o texto no campo**, sem enviar: quem confere o que foi
  /// entendido é a pessoa, não o reconhecedor.
  Future<void> _dictate() async {
    setState(() => _listening = true);
    final heard = await ref.read(speechInputProvider).listen();
    if (!mounted) return;
    setState(() {
      _listening = false;
      if (heard != null && heard.isNotEmpty) _text.text = heard;
    });
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocus)
      ..dispose();
    _text.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (_focus.hasFocus) widget.onFocused?.call();
  }

  void _send() {
    final question = _text.text.trim();
    if (question.isEmpty || !widget.enabled) return;
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
        Expanded(child: _field()),
        if (_canDictate) ...[
          const SizedBox(width: CajuiSpacing.sm),
          CajuiIconButton(
            icon: CajuiIconData.microphone,
            semanticLabel: _listening ? 'Ouvindo' : 'Ditar a pergunta',
            onPressed: widget.enabled && !_listening ? _dictate : null,
          ),
        ],
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

  Widget _field() => CajuiTextField(
    label: 'Sua pergunta',
    hint: 'Quanto sobra neste mês?',
    controller: _text,
    focusNode: _focus,
    enabled: widget.enabled,
    onChanged: (_) => setState(() {}),
    // Mandar pela tecla do teclado, sem procurar o botão.
    textInputAction: TextInputAction.send,
    onSubmitted: (_) => _send(),
  );
}
