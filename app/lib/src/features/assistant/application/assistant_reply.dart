import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/assistant/application/assistant_action_done.dart';
import 'package:meta/meta.dart';

/// O que voltou de uma pergunta ao assistente.
@immutable
sealed class AssistantReply {
  const new();
}

/// A resposta. Chega inteira: texto parcial da IA nunca é exibido (RN-946).
final class AssistantAnswered extends AssistantReply {
  /// Cria a resposta [text], com o que foi feito em [actions].
  const new(this.text, {this.actions = const [], this.isFallback = false});

  /// O texto. É mostrado como texto puro: nenhum endereço vira link (RN-948).
  final String text;

  /// O que o assistente fez no livro ao responder (ADR-021).
  final List<AssistantActionDone> actions;

  /// Se é a resposta de formato fixo, sem texto da IA.
  final bool isFallback;
}

/// Não deu, pelo motivo [code] do catálogo: sem rede, IA fora do ar, pausa
/// pedida pelo provedor, teto de tokens.
final class AssistantFailed extends AssistantReply {
  /// Cria a falha de código [code].
  const new(this.code, {this.retryAfterSeconds});

  /// O código do catálogo.
  final ErrorCode code;

  /// Em quanto tempo dá para perguntar de novo, quando o erro traz contagem.
  final int? retryAfterSeconds;
}
