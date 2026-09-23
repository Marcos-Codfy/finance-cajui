import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/assistant/application/answer_source.dart';
import 'package:cajui/src/features/assistant/application/assistant_gateway.dart';
import 'package:cajui/src/features/assistant/application/assistant_reply.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';

/// O caminho até o assistente que fala com o servidor de verdade.
///
/// Sobe **só a pergunta** (RN-915): o contexto com os números é montado no
/// servidor, e a chave da IA existe só lá. Aqui não há número para
/// forjar nem segredo para vazar — e é por isso que este adaptador é tão
/// curto.
final class HttpAssistantGateway implements AssistantGateway {
  /// Cria o caminho sobre a API do Cajui.
  const new(this._api);

  final CajuiApi _api;

  @override
  bool get isPaired => true;

  @override
  Future<AssistantReply> ask(String message) async {
    final outcome = await _api.authenticated(
      (token) =>
          _api.post('/v1/assistant/ask', {'message': message}, token: token),
    );
    if (outcome.body case final answer?) return _answer(answer);
    // Aparelho ainda desconhecido do servidor: não é falha, é cadastro que
    // falta — e a tela oferece o código em vez de um erro seco.
    final failure = outcome.failure;
    final code = failure?.code ?? ErrorCode.app01;
    if (code == ErrorCode.auth03) return const AssistantNotPaired();
    // O tempo de espera vem do servidor, que é quem sabe quanto falta do
    // limite. Antes ele se perdia aqui, e a tela chutava 60 segundos.
    return AssistantFailed(code, retryAfterSeconds: failure?.retryAfterSeconds);
  }

  AssistantReply _answer(Map<String, Object?> json) => AssistantAnswered(
    json['text']! as String,
    outOfScope: json['outOfScope'] as bool? ?? false,
    isFallback: json['fallback'] as bool? ?? false,
    sources: [
      for (final source in (json['sources'] as List?) ?? const [])
        if (source is Map) _source(source.cast<String, Object?>()),
    ],
  );

  AnswerSource _source(Map<String, Object?> json) => AnswerSource(
    label: json['label'] as String? ?? '',
    cents: json['cents'] as int? ?? 0,
    kind: json['kind'] as String? ?? '',
    period: json['period'] as String? ?? '',
  );
}
