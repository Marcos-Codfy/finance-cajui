import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:domain/domain.dart';
import 'package:server/src/ai/ai_receipt_classifier.dart';
import 'package:server/src/ai/chat_client.dart';
import 'package:server/src/ai/chat_message.dart';
import 'package:server/src/ai/chat_reply.dart';
import 'package:server/src/ai/chat_tool.dart';
import 'package:server/src/ai/chat_unavailable.dart';
import 'package:server/src/ai/circuit_breaker.dart';
import 'package:server/src/ai/receipt_routes.dart';
import 'package:test/test.dart';

import 'support/receipt_samples.dart';
import 'support/sample_bodies.dart';
import 'support/test_app.dart';

final Uint8List _photo = Uint8List.fromList([
  0xFF, 0xD8, 0xFF, 0xE0, //
  ...List.filled(64, 9),
]);

const _pix = 'Comprovante Pix\nValor R\$ 120,00\nMaria Souza\n12/09/2026';

ClassificationRequest _request(String text) => ClassificationRequest(
  text: ReceiptText.clean(text),
  categories: const [sampleGroceries, sampleRent],
  today: LocalDate(2026, 9, 20),
  images: [_photo],
);

/// Uma IA no ar que não aceita a imagem — recusa o pedido, como um provedor
/// que não lê aquele formato — ou que nunca responde quando vê uma. Ao texto
/// ela responde sempre.
final class _PickyChat extends ChatClient {
  new({this.hangsOnImages = false});

  final bool hangsOnImages;
  int textCalls = 0;
  int imageCalls = 0;

  @override
  Future<ChatReply> complete({
    required String system,
    required String user,
    required int maxTokens,
  }) async {
    textCalls++;
    return ChatReply(
      content: jsonEncode({'categoryId': 'groceries', 'confidence': 0.6}),
      promptTokens: 300,
      completionTokens: 20,
    );
  }

  @override
  Future<ChatReply> converse({
    required List<ChatMessage> messages,
    required int maxTokens,
    List<ChatTool> tools = const [],
    bool json = false,
  }) async {
    imageCalls++;
    if (hangsOnImages) return await Completer<ChatReply>().future;
    throw const ChatUnavailable(status: 400);
  }
}

Future<AiReceiptClassifier> _classifier(
  ChatClient client,
  CircuitBreaker breaker,
) async => AiReceiptClassifier(
  client: client,
  budget: await sampleBudget(),
  breaker: breaker,
  imageTimeout: const Duration(milliseconds: 20),
);

void main() {
  group('ADR-022 · quando a IA não aceita a foto', () {
    test('recusa da imagem: tenta uma vez só com o texto, e a IA ajuda do '
        'mesmo jeito', () async {
      final chat = _PickyChat();
      final classifier = await _classifier(chat, CircuitBreaker());

      final proposal = await classifier.classify(_request(_pix));

      expect(chat.imageCalls, 1);
      expect(chat.textCalls, 1);
      expect(proposal.category.candidates, contains('groceries'));
    });

    test('recusa não é queda: o disjuntor, que é o mesmo do assistente, '
        'continua fechado', () async {
      final breaker = CircuitBreaker();
      final classifier = await _classifier(_PickyChat(), breaker);

      for (var attempt = 0; attempt < 4; attempt++) {
        await classifier.classify(_request(_pix));
      }

      expect(breaker.allowsCall, isTrue);
    });

    test('foto sozinha recusada: não há texto para tentar, e as regras '
        'seguem', () async {
      final chat = _PickyChat();
      final classifier = await _classifier(chat, CircuitBreaker());

      final proposal = await classifier.classify(_request(''));

      expect(chat.textCalls, 0);
      expect(proposal.warnings, contains('E-AI-04'));
    });

    test('prazo vencido lendo foto não desliga o assistente', () async {
      final breaker = CircuitBreaker();
      final classifier = await _classifier(
        _PickyChat(hangsOnImages: true),
        breaker,
      );

      for (var attempt = 0; attempt < 4; attempt++) {
        final proposal = await classifier.classify(_request(_pix));
        expect(proposal.warnings, contains('E-AI-01'));
      }

      expect(breaker.allowsCall, isTrue);
    });
  });

  group('ADR-022 · a rota e os tetos', () {
    Future<(int, Map<String, Object?>)> classify(
      Map<String, Object?> body,
    ) async {
      final server = await TestApp.start();
      return await server.call(
        'POST',
        '/v1/receipts/classify',
        body: body,
        token: server.token(),
      );
    }

    test('RN-769 · mais de 20 exemplos: valem os últimos, e o pedido é '
        'aceito', () async {
      final (status, _) = await classify({
        'text': sampleCoupon,
        'examples': [
          for (var shop = 1; shop <= 25; shop++)
            {'merchant': 'loja $shop', 'categoryId': 'groceries'},
        ],
      });

      expect(status, 200);
    });

    test('corpo acima do teto da rota: 413, sem ler o resto', () async {
      final (status, body) = await classify({
        'text': sampleCoupon,
        'images': ['A' * (ReceiptRoutes.maxBodyBytes + 10)],
      });

      expect(status, 413);
      expect(errorOf(body)['code'], 'E-REQ-04');
    });

    test(
      'imagem acima do teto é pedido malformado, antes de decodificar',
      () async {
        final big = base64Encode([
          0xFF, 0xD8, 0xFF, //
          ...List.filled(ReceiptRoutes.maxImageBytes, 1),
        ]);

        final (status, _) = await classify({
          'text': sampleCoupon,
          'images': [big],
        });

        expect(status, 400);
      },
    );
  });
}
