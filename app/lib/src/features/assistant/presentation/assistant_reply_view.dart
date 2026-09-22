import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_notice.dart';
import 'package:cajui/src/core/errors/error_text.dart';
import 'package:cajui/src/core/errors/error_texts.g.dart';
import 'package:cajui/src/features/assistant/application/answer_source.dart';
import 'package:cajui/src/features/assistant/application/assistant_reply.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// O que voltou de uma pergunta, na conversa: a resposta com a origem dos
/// números, ou o erro do catálogo com as suas saídas.
class AssistantReplyView extends StatelessWidget {
  /// Mostra [reply]. [onRetry] pergunta de novo.
  const new({required this.reply, required this.onRetry, super.key});

  /// O que voltou.
  final AssistantReply reply;

  /// Chamado por "Perguntar de novo" e "Tentar de novo".
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => switch (reply) {
    AssistantAnswered(:final text, :final sources) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CajuiChatBubble(text),
        if (sources.isNotEmpty) _Sources(sources),
      ],
    ),
    AssistantFailed(:final code, :final retryAfterSeconds) => Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.md),
      child: ErrorNotice(
        error: (code: code, text: _textOf(code, retryAfterSeconds)),
        onAction: (_) => onRetry(),
      ),
    ),
    AssistantNotPaired() => const SizedBox.shrink(),
  };

  /// A frase do assistente para [code]. O catálogo traz, em alguns códigos,
  /// uma frase por tela; aqui vale a do assistente, e só a saída que faz
  /// sentido numa conversa.
  static ErrorText _textOf(ErrorCode code, int? retryAfterSeconds) {
    final text = ErrorTexts.of(code).inContext('No assistente').fill({
      'recurso': 'O assistente',
      'segundos': '${retryAfterSeconds ?? 60}',
      // Conversar não tem fila de envio: a frase do `E-APP-01` termina em
      // "continua salvo" e ponto. Sem isto, a falha sem nome derrubava a
      // própria tela que deveria contá-la.
      'fila': '',
      'mês': CalendarWords.month(
        LocalDate.fromDateTime(DateTime.now()).budgetMonth,
      ),
    });
    final retry = text.actions.where((a) => a.contains('de novo')).take(1);
    return ErrorText(text.message, actions: retry.toList());
  }
}

/// "De onde vieram os números" (RN-947): recolhida por padrão, e montada com
/// o que o servidor mandou — não com o texto da IA.
class _Sources extends StatefulWidget {
  const new(this.sources);

  final List<AnswerSource> sources;

  @override
  State<_Sources> createState() => _SourcesState();
}

class _SourcesState extends State<_Sources> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final muted = theme.typography.caption.copyWith(
      color: theme.colors.text.muted,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CajuiButton(
            label: _open ? 'Esconder os números' : 'De onde vieram os números',
            variant: CajuiButtonVariant.ghost,
            size: CajuiButtonSize.compact,
            onPressed: () => setState(() => _open = !_open),
          ),
          if (_open)
            for (final source in widget.sources)
              Text(
                '${source.label}: ${BrlFormatter.format(source.cents)} · '
                '${source.kindLabel}, ${source.period}',
                style: muted,
              ),
        ],
      ),
    );
  }
}
