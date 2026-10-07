import 'dart:convert';
import 'dart:typed_data';

import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/auth/application/device_key_store.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/receipts/application/read_outcome.dart';
import 'package:cajui/src/features/receipts/application/reading_strategy.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:cajui/src/features/receipts/application/shared_item.dart';
import 'package:cajui/src/features/receipts/infrastructure/http_receipt_classifier.dart';
import 'package:cajui/src/features/receipts/presentation/capture_state.dart';
import 'package:cajui/src/features/receipts/presentation/capture_view_model.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_household_key.dart';
import '../../support/fake_inbox.dart';
import '../../support/fake_reader.dart';
import '../../support/fake_server.dart';
import '../../support/test_scope.dart';

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

/// Um classificador que devolve sempre a mesma proposta: o que a IA teria
/// lido da foto.
final class _ReadsThePhoto implements ReceiptClassifier {
  const new(this.amount);

  final Money? amount;

  @override
  Future<EntryProposal> classify(ClassificationRequest request) async =>
      EntryProposal(
        documentKind: const ProposedField.resolved(
          DocumentKind.purchase,
          source: FieldSource.ai,
        ),
        amount: amount == null
            ? const ProposedField.unread()
            : ProposedField.resolved(amount!, source: FieldSource.ai),
        occurredOn: const ProposedField.unread(),
        category: const ProposedField.unread(),
        paymentKind: const ProposedField.unread(),
        description: 'Mercadinho do Zé',
      );
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
  });

  group('ADR-022 · foto que o celular não conseguiu ler', () {
    Future<CaptureState> arrive(ReceiptClassifier classifier) async {
      final inbox = FakeInbox();
      final container = ProviderContainer(
        overrides: [
          ...testOverrides(
            inbox: inbox,
            reader: FakeReader({
              '/inbox/escura': ReadText('', images: [_photo]),
            }),
          ),
          receiptClassifierProvider.overrideWithValue(classifier),
        ],
      );
      addTearDown(container.dispose);
      container.read(captureProvider);
      inbox.share(const [
        SharedFile(id: 'c1', path: '/inbox/escura', isPdf: false),
      ]);
      await pumpEventQueue();
      final settled = container.read(captureProvider);
      return settled;
    }

    test('a IA leu o valor: a conferência abre, preenchida', () async {
      final state = await arrive(const _ReadsThePhoto(Money.fromCents(2390)));

      expect(state, isA<CaptureReady>());
      final proposal = (state as CaptureReady).capture.proposal;
      expect(proposal.amount.value, const Money.fromCents(2390));
      expect(proposal.displayDescription, 'Mercadinho do Zé');
    });

    test('nem o celular nem a IA leram: a saída é a de sempre, outra foto ou '
        'digitar', () async {
      final state = await arrive(const _ReadsThePhoto(null));

      expect(state, isA<CaptureFailed>());
      expect((state as CaptureFailed).error.code, ErrorCode.capt01);
    });
  });
}
