import 'dart:convert';

import 'package:server/src/ai/chat_unavailable.dart';
import 'package:server/src/ai/deepseek_chat_client.dart';
import 'package:test/test.dart';

/// O corpo que o provedor devolve, com o motivo de parada [finish].
String _body(String finish) => jsonEncode({
  'choices': [
    {
      'message': {'content': '{"lines": ['},
      'finish_reason': finish,
    },
  ],
  'usage': {'prompt_tokens': 1200, 'completion_tokens': 4000},
});

void main() {
  group('RN-1103 · o servidor sabe quando a resposta foi cortada', () {
    test('"length" é resposta cortada pelo teto de tokens', () {
      final reply = DeepSeekChatClient.replyOf(_body('length'));

      expect(reply.truncated, isTrue);
      expect(reply.content, '{"lines": [');
      expect(reply.totalTokens, 5200);
    });

    test('"stop" é resposta inteira', () {
      expect(DeepSeekChatClient.replyOf(_body('stop')).truncated, isFalse);
    });

    test('corpo fora do formato é IA fora do ar', () {
      expect(
        () => DeepSeekChatClient.replyOf('{}'),
        throwsA(isA<ChatUnavailable>()),
      );
    });
  });
}
