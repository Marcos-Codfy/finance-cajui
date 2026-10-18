import 'dart:convert';

import 'package:server/src/ai/chat_message.dart';
import 'package:server/src/ai/chat_tool.dart';
import 'package:server/src/ai/chat_unavailable.dart';
import 'package:server/src/ai/claude_chat_client.dart';
import 'package:server/src/ai/claude_messages.dart';
import 'package:server/src/ai/tool_call.dart';
import 'package:test/test.dart';

void main() {
  group('a conversa do Cajui no formato da Anthropic', () {
    final conversation = [
      const ChatMessage.system('Você é a Juju.'),
      const ChatMessage.user('gastei 50 na padaria'),
      const ChatMessage.assistant(
        '',
        toolCalls: [
          ToolCall(
            id: 'c1',
            name: 'lancar_despesa',
            arguments: {'valor_centavos': 5000},
          ),
          ToolCall(id: 'c2', name: 'listar_lancamentos', arguments: {}),
        ],
      ),
      const ChatMessage.tool('{"ok":true}', toolCallId: 'c1'),
      const ChatMessage.tool('{"lancamentos":[]}', toolCallId: 'c2'),
    ];

    test('o sistema vai à parte, fora das mensagens', () {
      expect(ClaudeMessages.systemOf(conversation), 'Você é a Juju.');
      expect(ClaudeMessages.of(conversation).map((m) => m['role']), [
        'user',
        'assistant',
        'user',
      ]);
    });

    test('o pedido de ferramenta vira tool_use, e as respostas viram '
        'tool_result numa mensagem só do usuário', () {
      final [_, assistant, results] = ClaudeMessages.of(conversation);
      final calls = assistant['content']! as List<Map<String, Object?>>;
      final answers = results['content']! as List<Map<String, Object?>>;

      expect(calls.map((b) => b['type']), ['tool_use', 'tool_use']);
      expect(calls.first['input'], {'valor_centavos': 5000});
      expect(answers.map((b) => b['tool_use_id']), ['c1', 'c2']);
      expect(answers.first['type'], 'tool_result');
    });

    test('a imagem vai em base64, com o tipo dela', () {
      final [message] = ClaudeMessages.of([
        const ChatMessage.user(
          'o que tem aqui?',
          images: ['data:image/jpeg;base64,QUJD'],
        ),
      ]);
      final blocks = message['content']! as List<Map<String, Object?>>;

      expect(blocks.last, {
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': 'image/jpeg',
          'data': 'QUJD',
        },
      });
    });

    test('a ferramenta leva o esquema em input_schema', () {
      final [tool] = ClaudeMessages.toolsOf(const [
        ChatTool(
          name: 'listar_lancamentos',
          description: 'Os lançamentos.',
          parameters: {'type': 'object'},
        ),
      ]);

      expect(tool['input_schema'], {'type': 'object'});
    });

    test('a resposta junta o texto, lê as ferramentas e os tokens', () {
      final reply = ClaudeChatClient.replyOf(
        jsonEncode({
          'content': [
            {'type': 'text', 'text': 'Lancei '},
            {'type': 'text', 'text': r'R$ 50,00.'},
            {
              'type': 'tool_use',
              'id': 't1',
              'name': 'lancar_despesa',
              'input': {'valor_centavos': 5000},
            },
          ],
          'stop_reason': 'tool_use',
          'usage': {'input_tokens': 900, 'output_tokens': 40},
        }),
      );

      expect(reply.content, r'Lancei R$ 50,00.');
      expect(reply.toolCalls.single.name, 'lancar_despesa');
      expect(reply.toolCalls.single.arguments, {'valor_centavos': 5000});
      expect(reply.promptTokens, 900);
      expect(reply.truncated, isFalse);
    });

    test('resposta fora do formato é IA fora do ar, nunca erro solto', () {
      expect(
        () => ClaudeChatClient.replyOf('{"erro":true}'),
        throwsA(isA<ChatUnavailable>()),
      );
    });
  });
}
