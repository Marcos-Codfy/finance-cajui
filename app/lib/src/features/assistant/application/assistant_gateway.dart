import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/assistant/application/assistant_reply.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Por onde o app conversa com o assistente.
///
/// O app manda a pergunta e os números do mês que ele mostra na tela. O resto
/// do contexto é montado no servidor (RN-915), a chave da IA existe só lá
/// (RN-907), e é lá que o assistente lança e cancela quando a pessoa pede
/// (ADR-021). Os números vão junto porque o servidor só conhece o que já
/// sincronizou, e a Juju dizia uma sobra diferente da tela (15/10/2026).
abstract interface class AssistantGateway {
  /// Pergunta [message] e espera a resposta inteira. [month] são os números
  /// do mês como a tela mostra; nulo enquanto o registro não abriu.
  Future<AssistantReply> ask(String message, {MonthFigures? month});
}

/// O caminho até o assistente. A raiz do app decide qual.
final assistantGatewayProvider = Provider<AssistantGateway>(
  (ref) => throw StateError('assistantGatewayProvider sem override na raiz.'),
);
