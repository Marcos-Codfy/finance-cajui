import 'package:cajui/src/features/assistant/application/assistant_action_done.dart';
import 'package:cajui/src/features/assistant/application/assistant_gateway.dart';
import 'package:cajui/src/features/assistant/application/assistant_reply.dart';
import 'package:cajui/src/features/assistant/presentation/assistant_state.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O ViewModel da conversa com o assistente (ADR-002).
///
/// A conversa da tela vive só aqui, na memória: fechar o app a esquece.
///
/// Toda pergunta vai ao servidor (ADR-021): é lá que o assistente vê o mês,
/// pensa e age. Antes de perguntar, o livro sobe, para a resposta sair dos
/// números de agora; depois de uma resposta em que ele lançou ou cancelou,
/// o livro desce, para o que ele fez aparecer aqui — e dar para desfazer.
class AssistantViewModel extends Notifier<AssistantState> {
  @override
  AssistantState build() => const AssistantTalking();

  /// Pergunta [message]. Enquanto a resposta não chega, a tela espera: uma
  /// segunda pergunta só depois da primeira resposta.
  Future<void> ask(String message) async {
    final current = state;
    final question = message.trim();
    if (current is! AssistantTalking || current.isWaiting) return;
    if (question.isEmpty) return;
    state = current.asking(question);
    await _syncLedger();
    final reply = await ref.read(assistantGatewayProvider).ask(question);
    if (reply is AssistantAnswered && reply.actions.isNotEmpty) {
      await _refreshLedger();
    }
    state = current.answered(question, reply);
  }

  /// O que o assistente gravou no servidor chega aqui: no celular, pela
  /// descida; na consulta pela web, relendo o livro, que é o do servidor —
  /// no lugar, sem voltar ao "carregando".
  Future<void> _refreshLedger() async {
    if (ref.read(ledgerUplinkProvider).isPaired) {
      await _syncLedger();
      return;
    }
    await ref.read(ledgerProvider.notifier).reload();
  }

  /// Sobe o que falta e traz o que o servidor tem, na mesma fila da
  /// sincronização que acontece sozinha: duas ao mesmo tempo mandariam o
  /// mesmo lançamento duas vezes. Falha aqui não interrompe a pergunta: o
  /// assistente responde com o que o servidor já tinha.
  Future<void> _syncLedger() async {
    final book = ref.read(ledgerProvider).value;
    if (book == null) return;
    await ref.read(ledgerProvider.notifier).quietSync.request(book);
  }

  /// Desfaz o que o assistente lançou: cancela aqui, e o cancelamento sobe
  /// na sequência (RN-208). O lançamento já desceu com a resposta.
  Future<void> undo(AssistantActionDone action) => ref
      .read(ledgerProvider.notifier)
      .cancel(action.id, reason: 'Desfeito na conversa com o assistente');

  /// Pergunta de novo a última pergunta, depois de uma falha.
  Future<void> retry() async {
    final current = state;
    if (current is! AssistantTalking || current.exchanges.isEmpty) return;
    final (question, _) = current.exchanges.last;
    state = current.withoutLast();
    await ask(question);
  }
}

/// A conversa em curso.
final assistantProvider = NotifierProvider<AssistantViewModel, AssistantState>(
  AssistantViewModel.new,
);
