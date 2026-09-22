import 'package:cajui/src/features/assistant/presentation/assistant_composer.dart';
import 'package:cajui/src/features/assistant/presentation/assistant_reply_view.dart';
import 'package:cajui/src/features/assistant/presentation/assistant_state.dart';
import 'package:cajui/src/features/assistant/presentation/assistant_view_model.dart';
import 'package:cajui/src/features/auth/presentation/enroll_page.dart';
import 'package:cajui/src/features/insights/presentation/insights_page.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A conversa com o assistente: ele olha os números do mês e responde com a
/// conta na mão — nunca com conselho de investimento, nunca julgando gasto.
class AssistantPage extends ConsumerStatefulWidget {
  /// Cria a tela do assistente.
  const new({super.key});

  /// Três perguntas que o assistente sabe responder bem: a primeira conversa
  /// não começa diante de um campo vazio.
  static const _suggestions = [
    'Quanto dá para gastar nesta semana?',
    'Para onde foi o dinheiro deste mês?',
    'Como o mês está fechando?',
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
      AssistantUnpaired() => _unpaired(context, ref),
      AssistantTalking() => _talking(ref, state),
    };
  }

  Widget _unpaired(BuildContext context, WidgetRef ref) => CajuiScreen(
    title: 'Assistente',
    footer: CajuiButton(
      label: 'Ver os resumos',
      variant: CajuiButtonVariant.secondary,
      expand: true,
      onPressed: () => InsightsPage.open(context),
    ),
    children: [
      CajuiEmptyState(
        title: 'Esta pergunta precisa do servidor',
        message:
            'As contas do seu mês — semana, sobra, vale, fatura, para onde '
            'foi o dinheiro — o Cajui responde aqui mesmo, sem internet. '
            'Para conversar sobre o resto, o aparelho precisa estar '
            'cadastrado no seu servidor.',
        action: CajuiNoticeAction(
          label: 'Cadastrar este aparelho',
          onPressed: () => _enroll(context, ref),
        ),
      ),
    ],
  );

  /// Cadastrado, a conversa já pode começar: o estado volta a ser de quem
  /// tem com quem falar.
  static Future<void> _enroll(BuildContext context, WidgetRef ref) async {
    final enrolled = await EnrollPage.open(context);
    if (enrolled ?? false) ref.invalidate(assistantProvider);
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
          AssistantReplyView(reply: reply, onRetry: assistant.retry),
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
      title: 'Oi, eu sou o ${AssistantIdentity.name}',
      message:
          'Onde tem buriti, tem água. Eu olho os seus números e respondo '
          'com a conta na mão.',
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
