import 'package:cajui/src/features/assistant/application/assistant_reply.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Por onde o app conversa com o assistente.
///
/// O app manda **só a pergunta**. O resumo do mês é montado no servidor
/// (RN-915), a chave da IA existe só lá (RN-907), e é lá que o assistente
/// lança e cancela quando a pessoa pede (ADR-021): aqui não há número para
/// forjar nem segredo para vazar.
abstract interface class AssistantGateway {
  /// Pergunta [message] e espera a resposta inteira.
  Future<AssistantReply> ask(String message);
}

/// O caminho até o assistente. A raiz do app decide qual.
final assistantGatewayProvider = Provider<AssistantGateway>(
  (ref) => throw StateError('assistantGatewayProvider sem override na raiz.'),
);
