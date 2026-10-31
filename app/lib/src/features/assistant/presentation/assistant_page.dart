import 'package:cajui/src/core/navigation/coordinator_access.dart';
import 'package:cajui/src/features/assistant/application/answer_link.dart';
import 'package:cajui/src/features/assistant/application/assistant_reply.dart';
import 'package:cajui/src/features/assistant/application/assistant_suggestions.dart';
import 'package:cajui/src/features/assistant/presentation/assistant_composer.dart';
import 'package:cajui/src/features/assistant/presentation/assistant_reply_view.dart';
import 'package:cajui/src/features/assistant/presentation/assistant_state.dart';
import 'package:cajui/src/features/assistant/presentation/assistant_view_model.dart';
import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/budget/presentation/budget_coordinator.dart';
import 'package:cajui/src/features/debts/presentation/debts_coordinator.dart';
import 'package:cajui/src/features/home/application/home_view.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:cajui/src/features/ledger/application/today_controller.dart';
import 'package:cajui/src/features/receipts/presentation/capture_tools.dart';
import 'package:cajui/src/features/receipts/presentation/capture_view_model.dart';
import 'package:cajui/src/features/statements/presentation/statement_footer.dart';
import 'package:cajui/src/features/statements/presentation/statement_talk_state.dart';
import 'package:cajui/src/features/statements/presentation/statement_talk_view_model.dart';
import 'package:cajui/src/features/statements/presentation/statement_thread.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A conversa com a Juju, a tela principal do app (sugestão 3 do dono): diga
/// o que gastou e ela lança; pergunte e ela responde com os números do mês
/// na mão (ADR-021).
///
/// No alto, o mês de relance — a sobra, ou quanto falta — e a câmera e a
/// galeria: o mais comum do dia fica a um olhar e a um toque, sem trocar de
/// aba.
class AssistantPage extends ConsumerStatefulWidget {
  /// Cria a tela do assistente.
  const new({super.key});

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
    ref
      ..listen(assistantProvider, (_, _) => _followLatest())
      ..listen(statementTalkProvider, (_, _) => _followLatest());
    final state = ref.watch(assistantProvider);
    return switch (state) {
      AssistantTalking() => _talking(ref, state),
    };
  }

  Widget _talking(WidgetRef ref, AssistantTalking state) {
    final assistant = ref.read(assistantProvider.notifier);
    final pending = state.pending;
    final paired = ref.read(ledgerUplinkProvider).isPaired;
    final talk = ref.watch(statementTalkProvider);
    return CajuiScreen(
      title: AssistantIdentity.name,
      overline: _month(ref.watch(homeViewProvider)),
      trailing: CaptureTools(readOnly: !paired),
      controller: _scroll,
      footer: _footer(state, talk),
      children: [
        if (state.exchanges.isEmpty &&
            pending == null &&
            talk is StatementTalkIdle)
          ..._firstTalk(assistant.ask),
        ..._exchanges(state, canUndo: paired, waiting: pending != null),
        if (pending == null && talk is StatementTalkIdle)
          ..._followUps(assistant.ask, state),
        if (pending != null) ...[
          CajuiChatBubble(pending, fromUser: true),
          const CajuiChatBubble('', thinking: true),
        ],
        // O extrato conversa depois das trocas (RN-1100).
        if (talk is! StatementTalkIdle) const StatementThread(),
      ],
    );
  }

  /// Com o extrato aberto, o rodapé é o dele: "Pode lançar (N)" no lugar
  /// do campo de pergunta (RN-1115).
  Widget _footer(AssistantTalking state, StatementTalkState talk) =>
      talk is StatementTalkOpen
      ? StatementFooter(talk)
      : AssistantComposer(
          enabled: !state.isWaiting,
          onSend: ref.read(assistantProvider.notifier).ask,
          onFocused: _followLatest,
        );

  /// As trocas da conversa; só a última, já respondida, ganha "Pode/Não".
  List<Widget> _exchanges(
    AssistantTalking state, {
    required bool canUndo,
    required bool waiting,
  }) => [
    for (final (index, (question, reply)) in state.exchanges.indexed)
      ..._exchange(
        question,
        reply,
        canUndo: canUndo,
        last: !waiting && index == state.exchanges.length - 1,
      ),
  ];

  List<Widget> _exchange(
    String question,
    AssistantReply reply, {
    required bool canUndo,
    bool last = false,
  }) {
    final assistant = ref.read(assistantProvider.notifier);
    return [
      CajuiChatBubble(question, fromUser: true),
      AssistantReplyView(
        reply: reply,
        onRetry: assistant.retry,
        onUndo: assistant.undo,
        canUndo: canUndo,
        onQuickReply: last ? assistant.ask : null,
        onLink: (link) => switch (link) {
          AnswerLink.month =>
            context.coordinator(budgetCoordinatorProvider).openMonth(),
          AnswerLink.debts =>
            context.coordinator(debtsCoordinatorProvider).openDebts(),
        },
        // Só o celular tem conferência: a web é consulta (ADR-013).
        onCapture: canUndo && SpokenExpense.looksLikeExpense(question)
            ? () => ref
                  .read(captureProvider.notifier)
                  .startText(SpokenExpense.asReceipt(question))
            : null,
      ),
    ];
  }

  /// O mês de relance, com as palavras do Início: a sobra, ou quanto falta
  /// para fechar (RN-1060). Sem plano, o que já saiu no mês (RN-1050).
  static String? _month(HomeView? view) {
    if (view == null) return null;
    String brl(Money amount) => BrlFormatter.format(amount.cents);
    final budget = view.budget;
    if (!view.hasPlan) return 'Já saiu ${brl(budget.outOfPocket)} este mês';
    if (!budget.closes) {
      return 'Faltam ${brl(budget.shortfall)} para fechar o mês';
    }
    return 'Sobram ${brl(budget.result)} neste mês';
  }

  /// Três coisas para dizer: a primeira conversa não começa diante de um
  /// campo vazio, e as sugestões acompanham o mês.
  List<String> _suggestions() => AssistantSuggestions.of(
    ref.watch(financesProvider),
    ref.watch(todayProvider).budgetMonth,
    cardIds: _cardIds(),
  );

  Set<String> _cardIds() => {
    ...?ref.watch(ledgerProvider).value?.cards.map((card) => card.id),
  };

  /// O que vale perguntar depois da última resposta: acompanha o assunto da
  /// conversa e não repete o que ela já teve (24/10/2026).
  List<Widget> _followUps(ValueChanged<String> onAsk, AssistantTalking state) {
    final suggestions = AssistantSuggestions.after(
      state.exchanges,
      ref.watch(financesProvider),
      ref.watch(todayProvider).budgetMonth,
      cardIds: _cardIds(),
    );
    if (suggestions.isEmpty) return const [];
    return [_chips(suggestions, onAsk)];
  }

  Widget _chips(List<String> suggestions, ValueChanged<String> onAsk) => Wrap(
    spacing: CajuiSpacing.sm,
    runSpacing: CajuiSpacing.sm,
    children: [
      for (final suggestion in suggestions)
        CajuiChip(
          label: suggestion,
          selected: false,
          onSelected: (_) => onAsk(suggestion),
        ),
    ],
  );

  List<Widget> _firstTalk(ValueChanged<String> onAsk) => [
    const CajuiEmptyState(
      title: AssistantIdentity.greeting,
      message:
          'Diga o que gastou e eu lanço. Pergunte, e eu respondo com os '
          'seus números na mão.',
    ),
    const SizedBox(height: CajuiSpacing.lg),
    _chips(_suggestions(), onAsk),
  ];
}
