import 'dart:typed_data';

import 'package:cajui/src/features/auth/application/device_key_store.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/receipts/infrastructure/http_receipt_classifier.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_server.dart';
import '../../support/pix_receipt.dart';

/// Uma chave que assina devolvendo a mensagem; quem confere é o servidor.
final class _FakeKeys implements DeviceKeyStore {
  @override
  bool get exists => true;

  @override
  Future<bool> canAuthenticate() async => true;

  @override
  Future<Uint8List> publicKey() async => Uint8List.fromList([1, 2, 3, 4]);

  @override
  Future<Uint8List> sign(Uint8List message) async => message;
}

ClassificationRequest _request() => ClassificationRequest(
  text: pixReceiptText,
  categories: DefaultCatalog.emptyBook.categories,
  today: LocalDate(2026, 9, 22),
  learnedRules: const {'padaria central': 'bakery'},
);

void main() {
  late FakeServer server;
  late HttpReceiptClassifier classifier;
  late CajuiApi api;

  setUp(() async {
    server = await FakeServer.start();
    addTearDown(server.stop);
    api = CajuiApi(
      baseUrl: server.baseUrl,
      keys: _FakeKeys(),
      client: server.client,
    );
    classifier = HttpReceiptClassifier(api, const RuleBasedClassifier());
  });

  group('ADR-010 · a IA do servidor por cima das regras locais', () {
    test('sem sessão aberta, nem tenta o servidor: a digital não se pede no '
        'meio de uma conferência', () async {
      final proposta = await classifier.classify(_request());

      expect(server.paths, isEmpty);
      expect(proposta.amount.value, isNotNull, reason: 'as regras leram');
    });

    test('com sessão aberta, a proposta vem do servidor', () async {
      // Abre a sessão como o app abre: uma chamada autenticada qualquer.
      await api.devices();
      server.bodies['/v1/receipts/classify'] = const {
        'amountCents': {
          'value': 12345,
          'candidates': <Object?>[],
          'confidence': 'high',
          'source': 'ai',
        },
        'categoryId': {
          'value': 'groceries',
          'candidates': <Object?>[],
          'confidence': 'high',
          'source': 'ai',
        },
        'merchant': 'Mercado da Esquina',
        'warnings': <Object?>[],
      };

      final proposta = await classifier.classify(_request());

      expect(server.paths, contains('/v1/receipts/classify'));
      expect(proposta.amount.value, const Money.fromCents(12345));
      expect(proposta.category.value, 'groceries');
      expect(proposta.merchant, 'Mercado da Esquina');
    });

    test('RN-742 · categoria que este aparelho não conhece cai fora', () async {
      await api.devices();
      server.bodies['/v1/receipts/classify'] = const {
        'categoryId': {
          'value': 'categoria-inventada',
          'candidates': <Object?>[],
          'confidence': 'high',
          'source': 'ai',
        },
        'warnings': <Object?>[],
      };

      final proposta = await classifier.classify(_request());

      expect(proposta.category.value, isNull);
    });

    test(
      'RN-752 · servidor fora do ar cai nas regras, e nada quebra',
      () async {
        await api.devices();
        await server.stop();

        final proposta = await classifier.classify(_request());

        expect(proposta.amount.value, isNotNull);
      },
    );

    test(
      'T-24 · só o texto sai daqui, e o que o app aprendeu vai junto',
      () async {
        await api.devices();
        server.bodies['/v1/receipts/classify'] = const {
          'warnings': <Object?>[],
        };

        await classifier.classify(_request());

        final pedido = server.requests.firstWhere(
          (r) => r.path == '/v1/receipts/classify',
        );
        expect(pedido.body.keys, {'text', 'examples'});
        expect(pedido.body['text'], contains('SABOR DA'));
        expect((pedido.body['examples']! as List).single, {
          'merchant': 'padaria central',
          'categoryId': 'bakery',
        });
      },
    );
  });
}
