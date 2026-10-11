import 'package:cajui/src/features/assistant/presentation/assistant_composer.dart';
import 'package:cajui/src/features/assistant/presentation/assistant_reply_view.dart';
import 'package:cajui/src/features/assistant/presentation/assistant_state.dart';
import 'package:cajui/src/features/assistant/presentation/assistant_view_model.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A conversa com o assistente: diga o que gastou e ele lança; pergunte e
/// ele responde com os números do mês na mão (ADR-021).
class AssistantPage extends ConsumerStatefulWidget {
  /// Cria a tela do assistente.
  const new({super.key});

  /// Três coisas que o assistente faz bem: a primeira conversa não começa
  /// diante de um campo vazio.
  static const _suggestions = [
    'Gastei 35 no mercado',
    'Quanto dá para gastar nesta semana?',
    'Para onde foi o dinheiro deste mês?',
  ];

  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Leva a conversa ao fim depois que o quadro é desenhado.
  ///
  /// Só depois: a altura da mensagem nova ainda não existe enquanto ela não
  /// foi medida, e rolar antes disso para no lugar errado. Ler a resposta
  /// não pode depender de a pessoa lembrar de descer a tela.
  void _followLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: CajuiDurations.base,
        curve: CajuiCurves.enter,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pergunta enviada, resposta chegando ou erro: em qualquer troca, a
    // conversa desce sozinha.
    ref.listen(assistantProvider, (_, _) => _followLatest());
    final state = ref.watch(assistantProvider);
    return switch (state) {
      AssistantTalking() => _talking(ref, state),
    };
  }

  Widget _talking(WidgetRef ref, AssistantTalking state) {
    final assistant = ref.read(assistantProvider.notifier);
    final pending = state.pending;
    return CajuiScreen(
      title: 'Assistente',
      controller: _scroll,
      footer: AssistantComposer(
        enabled: !state.isWaiting,
        onSend: assistant.ask,
        onFocused: _followLatest,
      ),
      children: [
        if (state.exchanges.isEmpty && pending == null)
          ..._firstTalk(assistant.ask),
        for (final (question, reply) in state.exchanges) ...[
          CajuiChatBubble(question, fromUser: true),
          AssistantReplyView(
            reply: reply,
            onRetry: assistant.retry,
            onUndo: assistant.undo,
            canUndo: ref.read(ledgerUplinkProvider).isPaired,
          ),
        ],
        if (pending != null) ...[
          CajuiChatBubble(pending, fromUser: true),
          const CajuiChatBubble('', thinking: true),
        ],
      ],
    );
  }

  List<Widget> _firstTalk(ValueChanged<String> onAsk) => [
    const CajuiEmptyState(
      title: AssistantIdentity.greeting,
      message:
          'Diga o que gastou e eu lanço. Pergunte, e eu respondo com os '
          'seus números na mão.',
    ),
    const SizedBox(height: CajuiSpacing.lg),
    Wrap(
      spacing: CajuiSpacing.sm,
      runSpacing: CajuiSpacing.sm,
      children: [
        for (final suggestion in AssistantPage._suggestions)
          CajuiChip(
            label: suggestion,
            selected: false,
            onSelected: (_) => onAsk(suggestion),
          ),
      ],
    ),
  ];
}
