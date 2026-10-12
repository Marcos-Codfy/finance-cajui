import 'dart:typed_data';

import 'package:cajui/src/features/auth/application/device_key_store.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/receipts/infrastructure/http_receipt_classifier.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_household_key.dart';
import '../../support/fake_server.dart';
import '../../support/pix_receipt.dart';

/// A identidade do aparelho de teste: uma chave pública qualquer.
final class _FakeIdentity implements DeviceKeyStore {
  @override
  bool get exists => true;

  @override
  Future<Uint8List> publicKey() async => Uint8List.fromList([1, 2, 3, 4]);
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
  late FakeHouseholdKey keys;

  setUp(() async {
    server = await FakeServer.start();
    addTearDown(server.stop);
    keys = FakeHouseholdKey();
    final api = CajuiApi(
      baseUrl: server.baseUrl,
      keys: keys,
      identity: _FakeIdentity(),
      client: server.client,
    );
    classifier = HttpReceiptClassifier(api, const RuleBasedClassifier());
  });

  group('ADR-010 · a IA do servidor por cima das regras locais', () {
    test(
      'sem a chave da casa, nem tenta o servidor: as regras bastam',
      () async {
        keys.key = null;

        final proposta = await classifier.classify(_request());

        expect(server.paths, isEmpty);
        expect(proposta.amount.value, isNotNull, reason: 'as regras leram');
      },
    );

    test('ADR-020 · com a chave da casa, a proposta vem do servidor, e a '
        'chave vai no cabeçalho com o nome do aparelho', () async {
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
      final pedido = server.requests.single;
      expect(pedido.authorization, 'Bearer ${keys.key}');
      expect(pedido.device, isNotEmpty);
    });

    test('RN-742 · categoria que este aparelho não conhece cai fora', () async {
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
        await server.stop();

        final proposta = await classifier.classify(_request());

        expect(proposta.amount.value, isNotNull);
      },
    );

    test(
      'T-24 · só o texto sai daqui, e o que o app aprendeu vai junto',
      () async {
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

    test('RN-1107 · a regra que fala de pessoa não sai do celular', () async {
      server.bodies['/v1/receipts/classify'] = const {'warnings': <Object?>[]};

      await classifier.classify(
        ClassificationRequest(
          text: pixReceiptText,
          categories: DefaultCatalog.emptyBook.categories,
          today: LocalDate(2026, 9, 22),
          learnedRules: const {'padaria central': 'bakery'},
          personalRules: const {
            'joao p silva': 'services',
            'pessoa:maria souza': 'groceries',
          },
        ),
      );

      final pedido = server.requests.firstWhere(
        (r) => r.path == '/v1/receipts/classify',
      );
      expect(pedido.body['examples'], [
        {'merchant': 'padaria central', 'categoryId': 'bakery'},
      ]);
    });
  });
}
