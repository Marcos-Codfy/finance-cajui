import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_notice.dart';
import 'package:cajui/src/core/errors/error_text.dart';
import 'package:cajui/src/core/errors/error_texts.g.dart';
import 'package:cajui/src/features/assistant/application/assistant_action_done.dart';
import 'package:cajui/src/features/assistant/application/assistant_reply.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// O que voltou de uma pergunta, na conversa: a resposta, com o que o
/// assistente fez e o botão de desfazer, ou o erro do catálogo.
class AssistantReplyView extends StatefulWidget {
  /// Mostra [reply]. [onRetry] pergunta de novo; [onUndo] desfaz uma ação.
  /// Com [onCapture], a falha oferece lançar a frase pela conferência.
  const new({
    required this.reply,
    required this.onRetry,
    required this.onUndo,
    this.canUndo = true,
    this.onCapture,
    super.key,
  });

  /// Se este aparelho pode desfazer: só o celular grava. Na consulta pela
  /// web o botão não aparece — lá, gravar estoura por construção (T-12).
  final bool canUndo;

  /// O que voltou.
  final AssistantReply reply;

  /// Chamado por "Perguntar de novo" e "Tentar de novo".
  final VoidCallback onRetry;

  /// Chamado por "Desfazer", com a ação a desfazer.
  final Future<void> Function(AssistantActionDone action) onUndo;

  /// O caminho sem a Juju para um gasto dito (RN-1091): sem rede ou com a
  /// IA fora do ar, a frase abre a conferência, que funciona no aparelho.
  /// `null` quando a frase não conta um gasto.
  final VoidCallback? onCapture;

  /// A frase do assistente para [code]. O catálogo traz, em alguns códigos,
  /// uma frase por tela; aqui vale a do assistente, e só a saída que faz
  /// sentido numa conversa.
  ///
  /// Qualquer código pode chegar aqui — o servidor devolve o que ele quiser
  /// —, e chave sem valor derruba a tela que deveria contar o erro. Quando
  /// falta valor para montar a frase exata, sai a genérica: **dizer menos é
  /// melhor do que cair**. Um teste percorre o catálogo inteiro.
  static ErrorText textOf(ErrorCode code, {int? retryAfterSeconds}) {
    final values = {
      'recurso': 'O assistente',
      'segundos': '${retryAfterSeconds ?? 60}',
      // Conversar não tem fila de envio: a frase do `E-APP-01` termina em
      // "continua salvo" e ponto.
      'fila': '',
      'ação': 'responder',
      'mês': CalendarWords.month(
        LocalDate.fromDateTime(DateTime.now()).budgetMonth,
      ),
    };
    final catalog = ErrorTexts.of(code).inContext('No assistente');
    final missing = catalog.placeholders.difference(values.keys.toSet());
    final text = missing.isEmpty
        ? catalog.fill(values)
        : ErrorTexts.of(ErrorCode.srv01).fill(values);
    final retry = text.actions.where((a) => a.contains('de novo')).take(1);
    return ErrorText(text.message, actions: retry.toList());
  }

  @override
  State<AssistantReplyView> createState() => _AssistantReplyViewState();
}

class _AssistantReplyViewState extends State<AssistantReplyView> {
  /// O que já foi desfeito nesta resposta: o botão vira "Desfeito".
  final Set<String> _undone = {};

  /// Se a saída da falha já foi usada — "Tentar de novo" ou "Lançar pela
  /// conferência". Usada, as duas somem desta resposta: um segundo toque
  /// lançaria o mesmo gasto outra vez.
  bool _used = false;

  void _once(VoidCallback action) {
    if (_used) return;
    setState(() => _used = true);
    action();
  }

  Future<void> _undo(AssistantActionDone action) async {
    // A folha: desfeito a pedido de quem usa (escolha 4 do dono).
    CajuiFeedbackScope.of(context).undone();
    setState(() => _undone.add(action.id));
    await widget.onUndo(action);
  }

  @override
  Widget build(BuildContext context) => switch (widget.reply) {
    AssistantAnswered(:final text, :final actions) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A resposta nova chega palavra por palavra (escolha 7 do dono).
        CajuiChatBubble(text, streamed: true),
        for (final action in actions)
          if (widget.canUndo && action.isUndoable) _undoRow(context, action),
      ],
    ),
    AssistantFailed(:final code, :final retryAfterSeconds) => Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ErrorNotice(
            error: (code: code, text: _failure(code, retryAfterSeconds)),
            onAction: (_) => _once(widget.onRetry),
          ),
          if (!_used) ?_capture(),
        ],
      ),
    ),
  };

  /// O texto da falha; depois de usada a saída, sem botão.
  ErrorText _failure(ErrorCode code, int? retryAfterSeconds) {
    final text = AssistantReplyView.textOf(
      code,
      retryAfterSeconds: retryAfterSeconds,
    );
    return _used ? ErrorText(text.message) : text;
  }

  /// "Lançar pela conferência", quando a frase é um gasto dito.
  Widget? _capture() {
    final capture = widget.onCapture;
    if (capture == null) return null;
    return Padding(
      padding: const EdgeInsets.only(top: CajuiSpacing.sm),
      child: CajuiButton(
        label: 'Lançar pela conferência',
        icon: CajuiIconData.receipt,
        variant: CajuiButtonVariant.secondary,
        onPressed: () => _once(capture),
      ),
    );
  }

  /// "Desfazer" ao lado do que foi lançado: um toque, sem pergunta. Já
  /// desfeito, a linha fica como registro do que aconteceu.
  Widget _undoRow(BuildContext context, AssistantActionDone action) {
    final theme = CajuiTheme.of(context);
    final done = _undone.contains(action.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${action.label} · ${BrlFormatter.format(action.amountCents)}',
              style: theme.typography.caption.copyWith(
                color: theme.colors.text.muted,
              ),
            ),
          ),
          CajuiButton(
            label: done ? 'Desfeito' : 'Desfazer',
            variant: CajuiButtonVariant.ghost,
            size: CajuiButtonSize.compact,
            // Mudo: o toque abafaria a folha.
            silent: true,
            onPressed: done ? null : () => _undo(action),
          ),
        ],
      ),
    );
  }
}
