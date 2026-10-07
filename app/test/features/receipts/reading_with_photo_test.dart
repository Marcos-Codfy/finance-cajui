import 'dart:convert';
import 'dart:typed_data';

import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/auth/application/device_key_store.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/receipts/application/reading_strategy.dart';
import 'package:cajui/src/features/receipts/infrastructure/http_receipt_classifier.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_household_key.dart';
import '../../support/fake_server.dart';

/// O cupom de supermercado como o celular o lê: valor ao lado do rótulo,
/// data, e o nome do lugar dizendo o ramo.
const _market = r'''
MAR DOCE SUPERMERCADOS LTDA
12/09/2026 10:31
Valor a Pagar R$ 653,58
DEBITO''';

/// Um Pix para uma pessoa: o nome não diz ramo nenhum, e a categoria fica
/// para a IA.
const _pixToPerson = r'''
Comprovante de transferência Pix
Valor R$ 120,00
Destino
Nome: Maria Aparecida Souza
Data 12/09/2026''';

/// Uma foto qualquer, com a assinatura de JPEG.
final Uint8List _photo = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3]);

ClassificationRequest _request(
  String text, {
  List<Uint8List> images = const [],
}) => ClassificationRequest(
  text: text,
  categories: DefaultCatalog.emptyBook.categories,
  today: LocalDate(2026, 9, 20),
  categoryByMerchantKind: DefaultCatalog.categoryByMerchantKind,
  images: images,
);

final class _Identity implements DeviceKeyStore {
  @override
  bool get exists => true;

  @override
  Future<Uint8List> publicKey() async => Uint8List.fromList([9, 9]);
}

void main() {
  group('ADR-022 · quando a regra do celular basta', () {
    test(
      'cupom de mercado com o valor rotulado, data e nome do lugar: basta',
      () async {
        final local = await const RuleBasedClassifier().classify(
          _request(_market),
        );

        expect(ReadingStrategy.rulesSuffice(local), isTrue);
      },
    );

    test(
      'Pix para uma pessoa, sem ramo no nome: não basta, a IA ajuda',
      () async {
        final local = await const RuleBasedClassifier().classify(
          _request(_pixToPerson),
        );

        expect(ReadingStrategy.rulesSuffice(local), isFalse);
      },
    );

    test('RN-111 · cupom de mercado pago no vale: a regra lê o vale, e o vale '
        'não vira dinheiro', () async {
      final local = await const RuleBasedClassifier().classify(
        _request(_market.replaceFirst('DEBITO', 'Cartao Vale Alimentacao')),
      );

      expect(local.paymentKind.value, PaymentMethodKind.mealVoucher);
    });

    test(
      'cupom de mercado sem a forma de pagamento: não basta, a IA ajuda',
      () async {
        final local = await const RuleBasedClassifier().classify(
          _request(_market.replaceFirst('DEBITO', '')),
        );

        expect(ReadingStrategy.rulesSuffice(local), isFalse);
      },
    );

    test(
      'o ramo do lugar, que só o celular lê, entra depois do palpite da IA',
      () {
        const empty = ProposedField<Never>.unread();
        EntryProposal proposal(ProposedField<String> category) => EntryProposal(
          documentKind: const ProposedField.resolved(
            DocumentKind.purchase,
            source: FieldSource.fixedRule,
          ),
          amount: empty,
          occurredOn: empty,
          category: category,
          paymentKind: empty,
        );

        final blended = ReadingStrategy.blend(
          proposal(
            const ProposedField.undecided(['bakery'], source: FieldSource.ai),
          ),
          proposal(
            const ProposedField.undecided([
              'groceries',
            ], source: FieldSource.fixedRule),
          ),
        );
        final aiSaidNothing = ReadingStrategy.blend(
          proposal(const ProposedField.unread()),
          proposal(
            const ProposedField.undecided([
              'groceries',
            ], source: FieldSource.fixedRule),
          ),
        );

        expect(blended.category.candidates, ['bakery', 'groceries']);
        expect(aiSaidNothing.category.candidates, ['groceries']);
      },
    );
  });

  group('ADR-022 · o que sai do celular', () {
    late FakeServer server;
    late HttpReceiptClassifier classifier;

    setUp(() async {
      server = await FakeServer.start();
      addTearDown(server.stop);
      server.bodies['/v1/receipts/classify'] = const {'warnings': <Object?>[]};
      classifier = HttpReceiptClassifier(
        CajuiApi(
          baseUrl: server.baseUrl,
          keys: FakeHouseholdKey(),
          identity: _Identity(),
          client: server.client,
        ),
        const RuleBasedClassifier(),
      );
    });

    test(
      'cupom de mercado que a regra leu inteiro não sai do celular',
      () async {
        await classifier.classify(_request(_market, images: [_photo]));

        expect(server.paths, isEmpty);
      },
    );

    test(
      'quando a regra não basta, a foto vai junto do texto, em base64',
      () async {
        await classifier.classify(_request(_pixToPerson, images: [_photo]));

        final sent = server.requests.single.body;
        expect(sent['images'], [base64Encode(_photo)]);
        expect(sent['text'], contains('Maria Aparecida'));
      },
    );

    test('foto que o celular não leu: vai só a foto', () async {
      await classifier.classify(_request('', images: [_photo]));

      final sent = server.requests.single.body;
      expect(sent.containsKey('text'), isFalse);
      expect(sent['images'], hasLength(1));
    });

    test('sem texto e sem foto, nada sai: o servidor só recusaria', () async {
      await classifier.classify(_request(''));

      expect(server.paths, isEmpty);
    });

    test('servidor que ainda não conhece foto recusa: o texto vai de novo, '
        'sozinho, e a IA continua ajudando', () async {
      server.refuseOnceWith(ErrorCode.req04, status: 413);

      await classifier.classify(_request(_pixToPerson, images: [_photo]));

      expect(server.requests, hasLength(2));
      final retry = server.requests.last.body;
      expect(retry.containsKey('images'), isFalse);
      expect(retry['text'], contains('Maria Aparecida'));
    });

    test('foto sozinha recusada não tenta de novo: sem texto não há o que '
        'mandar', () async {
      server.refuseOnceWith(ErrorCode.req01, status: 400);

      await classifier.classify(_request('', images: [_photo]));

      expect(server.requests, hasLength(1));
    });

    test('RN-769 · com mais de 20 lojas aprendidas, vão as 20 mais recentes, e '
        'o pedido não é recusado', () async {
      final request = ClassificationRequest(
        text: _pixToPerson,
        categories: DefaultCatalog.emptyBook.categories,
        today: LocalDate(2026, 9, 20),
        learnedRules: {
          for (var shop = 1; shop <= 25; shop++) 'loja $shop': 'groceries',
          'x' * 81: 'groceries',
        },
      );

      await classifier.classify(request);

      final examples = server.requests.single.body['examples']! as List;
      expect(examples, hasLength(HttpReceiptClassifier.maxExamples));
      expect((examples.first as Map)['merchant'], 'loja 6');
      expect((examples.last as Map)['merchant'], 'loja 25');
    });
  });
}
