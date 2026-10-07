import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/assistant/application/assistant_action_done.dart';
import 'package:cajui/src/features/assistant/application/assistant_gateway.dart';
import 'package:cajui/src/features/assistant/application/assistant_reply.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';

/// O caminho até o assistente que fala com o servidor de verdade.
///
/// Sobe **só a pergunta** (RN-915) e traz o texto e o que o assistente fez
/// no livro (ADR-021). É curto porque o resto — contexto, chave da IA,
/// ferramentas — mora no servidor.
final class HttpAssistantGateway implements AssistantGateway {
  /// Cria o caminho sobre a API do Cajui.
  const new(this._api);

  final CajuiApi _api;

  @override
  Future<AssistantReply> ask(String message) async {
    final outcome = await _api.authenticated(
      (token) =>
          _api.post('/v1/assistant/ask', {'message': message}, token: token),
    );
    if (outcome.body case final answer?) return _answer(answer);
    // O tempo de espera vem do servidor, que é quem sabe quanto falta do
    // limite. Antes ele se perdia aqui, e a tela chutava 60 segundos.
    final failure = outcome.failure;
    return AssistantFailed(
      failure?.code ?? ErrorCode.app01,
      retryAfterSeconds: failure?.retryAfterSeconds,
    );
  }

  AssistantReply _answer(Map<String, Object?> json) => AssistantAnswered(
    json['text']! as String,
    isFallback: json['fallback'] as bool? ?? false,
    actions: [
      for (final action in (json['actions'] as List?) ?? const [])
        if (action is Map)
          AssistantActionDone.fromJson(action.cast<String, Object?>()),
    ],
  );
}
