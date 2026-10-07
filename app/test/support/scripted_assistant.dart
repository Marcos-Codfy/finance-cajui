import 'dart:async';

import 'package:cajui/src/features/assistant/application/assistant_gateway.dart';
import 'package:cajui/src/features/assistant/application/assistant_reply.dart';

/// Um assistente que responde o que o teste combinou, na ordem dada, e só
/// quando o teste manda — para dar tempo de ver a tela esperando.
class ScriptedAssistant implements AssistantGateway {
  /// Cria o assistente com as respostas [replies].
  new(this.replies);

  /// As respostas, na ordem em que saem; a última se repete.
  final List<AssistantReply> replies;

  /// As perguntas recebidas.
  final List<String> asked = [];

  Completer<void>? _gate;

  /// Faz a próxima resposta esperar até [release] ser chamado.
  void hold() => _gate = Completer<void>();

  /// Solta a resposta que estava esperando.
  void release() => _gate?.complete();

  @override
  Future<AssistantReply> ask(String message) async {
    asked.add(message);
    await _gate?.future;
    _gate = null;
    return replies[asked.length <= replies.length
        ? asked.length - 1
        : replies.length - 1];
  }
}
