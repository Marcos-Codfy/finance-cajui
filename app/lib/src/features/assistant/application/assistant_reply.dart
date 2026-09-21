import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/assistant/application/answer_source.dart';
import 'package:meta/meta.dart';

/// O que voltou de uma pergunta ao assistente.
@immutable
sealed class AssistantReply {
  const new();
}

/// A resposta, já validada pelo servidor. Chega inteira: texto parcial da IA
/// nunca é exibido (RN-946).
final class AssistantAnswered extends AssistantReply {
  /// Cria a resposta [text], com as origens [sources].
  const new(
    this.text, {
    this.sources = const [],
    this.outOfScope = false,
    this.isFallback = false,
  });

  /// O texto. É mostrado como texto puro: nenhum endereço vira link (RN-948).
  final String text;

  /// De onde vieram os números (RN-947).
  final List<AnswerSource> sources;

  /// Se a pergunta ficou fora do que o assistente faz (RN-902).
  final bool outOfScope;

  /// Se é a resposta de formato fixo, sem texto da IA (RN-945).
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

/// Este aparelho ainda não está cadastrado no servidor, então não há com
/// quem conversar. Não é erro: é o estado de quem ainda não pareou.
final class AssistantNotPaired extends AssistantReply {
  /// Cria o estado de aparelho não cadastrado.
  const new();
}
