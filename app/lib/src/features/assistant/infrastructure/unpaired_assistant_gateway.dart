import 'package:cajui/src/features/assistant/application/assistant_gateway.dart';
import 'package:cajui/src/features/assistant/application/assistant_reply.dart';

/// O caminho até o assistente de um aparelho que ainda não foi cadastrado no
/// servidor: não há caminho.
///
/// O cadastro do aparelho — chave no Keystore, liberada por biometria, e o
/// código emitido no servidor (ADR-008) — chega com o passo de biometria. É
/// ele que troca este adaptador pelo que fala com a API. Até lá, o app diz a
/// verdade em vez de fingir uma conversa.
final class UnpairedAssistantGateway implements AssistantGateway {
  /// Cria o adaptador.
  const new();

  @override
  bool get isPaired => false;

  @override
  Future<AssistantReply> ask(String message) async =>
      const AssistantNotPaired();
}
