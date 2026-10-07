import 'dart:convert';
import 'dart:typed_data';

import 'package:domain/domain.dart';
import 'package:server/src/ai/ai_receipt_classifier.dart';
import 'package:server/src/ai/chat_reply.dart';
import 'package:server/src/ai/chat_role.dart';
import 'package:server/src/ai/circuit_breaker.dart';
import 'package:test/test.dart';

import 'support/receipt_samples.dart';
import 'support/sample_bodies.dart';
import 'support/test_app.dart';
import 'support/tool_chat_client.dart';

/// Os primeiros bytes de um JPEG, e o resto qualquer: para o servidor, é a
/// assinatura que diz o que a imagem é.
final Uint8List _photo = Uint8List.fromList([
  0xFF, 0xD8, 0xFF, 0xE0, //
  ...List.filled(64, 7),
]);

ClassificationRequest _request(String text, {bool withPhoto = true}) =>
    ClassificationRequest(
      text: ReceiptText.clean(text),
      categories: const [sampleGroceries, sampleRent],
      today: LocalDate(2026, 9, 20),
      images: withPhoto ? [_photo] : const [],
    );

Future<(AiReceiptClassifier, ToolChatClient)> _classifier(
  Map<String, Object?> answer,
) async {
  final client = ToolChatClient([
    ChatReply(
      content: jsonEncode(answer),
      promptTokens: 1600,
      completionTokens: 90,
    ),
  ]);
  final classifier = AiReceiptClassifier(
    client: client,
    budget: await sampleBudget(),
    breaker: CircuitBreaker(),
  );
  return (classifier, client);
}

void main() {
  group('ADR-022 · a IA lê a foto junto do texto do celular', () {
    test('a foto vai na mesma mensagem que o texto lido, e a resposta é '
        'pedida em JSON', () async {
      final (classifier, client) = await _classifier({'confidence': 0.2});

      await classifier.classify(_request(sampleCoupon));
      final user = client.conversations.single.last;

      expect(user.role, ChatRole.user);
      expect(user.images.single, startsWith('data:image/jpeg;base64,'));
      expect(user.content, contains('MERCADO BOA COMPRA'));
      expect(client.jsonModes.single, isTrue);
      final sent = user.toJson()['content']! as List;
      expect((sent.last as Map)['type'], 'image_url');
    });

    test('o valor que o celular não leu vem da IA', () async {
      final (classifier, _) = await _classifier({
        'amountCents': 850,
        'confidence': 0.6,
      });

      final proposal = await classifier.classify(
        _request('PADARIA CENTRAL\n12/09/2026'),
      );

      expect(proposal.amount.value, const Money.fromCents(850));
      expect(proposal.amount.source, FieldSource.ai);
    });

    test('a IA desempata entre os números que o celular leu', () async {
      final (classifier, _) = await _classifier({'amountCents': 850});

      final proposal = await classifier.classify(
        _request('PADARIA CENTRAL\n8,50\n12,00\n12/09/2026'),
      );

      expect(proposal.amount.value, const Money.fromCents(850));
    });

    test('o rótulo TOTAL manda: se a IA diverge, os dois aparecem, o da '
        'regra primeiro', () async {
      final (classifier, _) = await _classifier({'amountCents': 8460});

      final proposal = await classifier.classify(_request(sampleCoupon));

      expect(proposal.amount.value, isNull);
      expect(proposal.amount.candidates.map((m) => m.cents), [8640, 8460]);
    });

    test(
      'sem foto, valor fora do texto continua descartado (RN-774)',
      () async {
        final (classifier, _) = await _classifier({'amountCents': 9999});

        final proposal = await classifier.classify(
          _request(sampleCoupon, withPhoto: false),
        );

        expect(proposal.amount.value, const Money.fromCents(8640));
      },
    );

    test('comprovante que o celular não conseguiu ler: só a imagem, e a IA '
        'lê tudo', () async {
      final (classifier, _) = await _classifier({
        'documentKind': 'purchase',
        'amountCents': 2390,
        'occurredOn': '2026-09-18',
        'categoryId': 'groceries',
        'confidence': 0.9,
        'description': 'Mercadinho do Zé',
        'paymentKind': 'pix',
      });

      final proposal = await classifier.classify(_request(''));

      expect(proposal.amount.value, const Money.fromCents(2390));
      expect(proposal.occurredOn.value, LocalDate(2026, 9, 18));
      expect(proposal.paymentKind.value, PaymentMethodKind.pix);
      expect(proposal.category.candidates.first, 'groceries');
      expect(proposal.displayDescription, 'Mercadinho do Zé');
      expect(proposal.merchant, 'Mercadinho do Zé', reason: 'para aprender');
    });

    test('Pix recebido: sem palavra que as regras reconheçam, vale o tipo que '
        'a IA viu', () async {
      final (classifier, _) = await _classifier({
        'documentKind': 'incomeReceipt',
        'amountCents': 5000,
      });

      final proposal = await classifier.classify(
        _request('Comprovante Pix\nR\$ 50,00\n15/09/2026'),
      );

      expect(proposal.documentKind.value, DocumentKind.incomeReceipt);
    });

    test('data da imagem no futuro, ou velha demais, não vale', () async {
      final (future, _) = await _classifier({'occurredOn': '2026-12-01'});
      final (old, _) = await _classifier({'occurredOn': '2019-01-01'});

      final ahead = await future.classify(_request('PADARIA\n8,50'));
      final ancient = await old.classify(_request('PADARIA\n8,50'));

      expect(ahead.occurredOn.value, isNull);
      expect(ancient.occurredOn.value, isNull);
    });

    test('RN-778 · a mesma foto não paga duas vezes; outra foto com o mesmo '
        'texto paga', () async {
      final (classifier, client) = await _classifier({'amountCents': 850});
      final other = Uint8List.fromList([..._photo, 1]);

      await classifier.classify(_request('PADARIA\n8,50\n12,00'));
      await classifier.classify(_request('PADARIA\n8,50\n12,00'));
      await classifier.classify(
        ClassificationRequest(
          text: 'PADARIA\n8,50\n12,00',
          categories: const [sampleGroceries],
          today: LocalDate(2026, 9, 20),
          images: [other],
        ),
      );

      expect(client.conversations, hasLength(2));
    });
  });

  group('ADR-022 · a rota recebe as imagens', () {
    Future<(int, Map<String, Object?>)> classify(
      TestApp server,
      Map<String, Object?> body,
    ) => server.call(
      'POST',
      '/v1/receipts/classify',
      body: body,
      token: server.token(),
    );

    test('foto com texto, e foto sozinha, são aceitas — mesmo acima do teto '
        'de 64 KB das outras rotas', () async {
      final server = await TestApp.start();
      final big = base64Encode([0xFF, 0xD8, 0xFF, ...List.filled(120000, 1)]);

      final (withText, _) = await classify(server, {
        'text': sampleCoupon,
        'images': [big],
      });
      final (alone, _) = await classify(server, {
        'images': [big],
      });

      expect(withText, 200);
      expect(alone, 200);
    });

    test('o que não é imagem, imagem demais ou nada para ler é pedido '
        'malformado', () async {
      final server = await TestApp.start();
      final photo = base64Encode(_photo);

      final (notImage, body) = await classify(server, {
        'text': sampleCoupon,
        'images': [base64Encode(utf8.encode('não sou imagem'))],
      });
      final (tooMany, _) = await classify(server, {
        'images': [photo, photo, photo, photo],
      });
      final (nothing, _) = await classify(server, {'text': ''});

      expect(notImage, 400);
      expect(errorOf(body)['code'], 'E-REQ-01');
      expect(tooMany, 400);
      expect(nothing, 400);
    });
  });
}
