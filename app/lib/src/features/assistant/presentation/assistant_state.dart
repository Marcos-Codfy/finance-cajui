import 'package:cajui/src/features/assistant/application/assistant_reply.dart';
import 'package:meta/meta.dart';

/// Os estados da tela do assistente. A tela faz `switch` exaustivo (ADR-002).
@immutable
sealed class AssistantState {
  const new();
}

/// O aparelho ainda não está cadastrado no servidor: não há com quem
/// conversar, e a tela diz isso.
final class AssistantUnpaired extends AssistantState {
  /// Cria o estado de aparelho não cadastrado.
  const new();
}

/// A conversa: as trocas já feitas e, se houver, a pergunta à espera.
final class AssistantTalking extends AssistantState {
  /// Cria a conversa.
  const new({this.exchanges = const [], this.pending});

  /// As trocas, da mais antiga para a mais nova: a pergunta e o que voltou.
  final List<(String question, AssistantReply reply)> exchanges;

  /// A pergunta que espera resposta. A resposta só aparece inteira, depois
  /// de validada (RN-946): até lá, a tela mostra que está esperando.
  final String? pending;

  /// Se há pergunta esperando.
  bool get isWaiting => pending != null;

  /// A mesma conversa, esperando a resposta de [question].
  AssistantTalking asking(String question) =>
      AssistantTalking(exchanges: exchanges, pending: question);

  /// A mesma conversa, com a troca [question] → [reply] no fim.
  AssistantTalking answered(String question, AssistantReply reply) =>
      AssistantTalking(exchanges: [...exchanges, (question, reply)]);

  /// A mesma conversa sem a última troca, para perguntar de novo.
  AssistantTalking withoutLast() =>
      AssistantTalking(exchanges: exchanges.sublist(0, exchanges.length - 1));
}
