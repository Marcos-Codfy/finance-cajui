import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/storage/memory_event_store.dart';
import 'package:cajui/src/features/ledger/application/answer_memory.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/infrastructure/event_store_ledger_journal.dart';
import 'package:cajui/src/features/ledger/infrastructure/ledger_event_codec.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_exchange.dart';
import '../../support/test_scope.dart';
import '../../support/two_phones.dart';

const _bakery = 'padaria boa vista';

AnswerMemory _memory(ProviderContainer phone) =>
    phone.read(answerMemoryProvider);

Future<LearnedAnswer?> _answerOn(ProviderContainer phone, String key) async =>
    (await phone.read(ledgerProvider.future)).learnedAnswers.forKey(key);

void main() {
  late FakeExchange server;
  late ProviderContainer a;
  late ProviderContainer b;

  setUp(() {
    server = FakeExchange();
    a = TwoPhones.on(server);
    b = TwoPhones.on(server, today: testToday.addDays(1));
  });

  group('RN-1116 · a resposta lembrada atravessa os celulares', () {
    test('lembrada num celular, aparece no outro', () async {
      await _memory(a).remember(key: _bakery, categoryId: 'bakery');
      await TwoPhones.sync(a);

      await TwoPhones.sync(b);

      expect((await _answerOn(b, _bakery))?.categoryId, 'bakery');
      expect(server.facts.single.type, DeviceFact.merchantLearned);
    });

    test('a mais nova vence nos dois, venha na ordem que vier', () async {
      // O celular B responde um dia depois, mas sincroniza primeiro.
      await _memory(b).remember(key: _bakery, categoryId: 'bakery');
      await TwoPhones.sync(b);
      await _memory(a).remember(key: _bakery, categoryId: 'groceries');

      await TwoPhones.sync(a);
      await TwoPhones.sync(b);

      expect((await _answerOn(a, _bakery))?.categoryId, 'bakery');
      expect((await _answerOn(b, _bakery))?.categoryId, 'bakery');
    });

    test('responder de novo troca a anterior', () async {
      await _memory(a).remember(key: _bakery, categoryId: 'groceries');
      await _memory(a).remember(key: _bakery, categoryId: 'bakery');

      expect((await _answerOn(a, _bakery))?.categoryId, 'bakery');
    });

    test('a categoria dada depois de "É um gasto" leva o tipo junto', () async {
      await _memory(a).remember(key: _bakery, treatment: LineTreatment.expense);
      await _memory(a).remember(key: _bakery, categoryId: 'bakery');

      final answer = await _answerOn(a, _bakery);
      expect(answer?.categoryId, 'bakery');
      expect(answer?.treatment, LineTreatment.expense);
    });

    test('esquecida num celular, some no outro', () async {
      await _memory(a).remember(key: _bakery, categoryId: 'bakery');
      await TwoPhones.sync(a);
      await TwoPhones.sync(b);

      expect(await _memory(b).forget(_bakery), isTrue);
      await TwoPhones.sync(b);
      await TwoPhones.sync(a);

      expect(await _answerOn(a, _bakery), isNull);
      expect(await _answerOn(b, _bakery), isNull);
    });

    test('esquecer depois de ver a resposta do outro vale, mesmo com o '
        'relógio daqui atrasado', () async {
      // B responde no dia 21; A, com o relógio no dia 20, vê e esquece.
      await _memory(b).remember(key: _bakery, categoryId: 'groceries');
      await TwoPhones.sync(b);
      await TwoPhones.sync(a);
      await _memory(a).forget(_bakery);
      await TwoPhones.sync(a);

      await TwoPhones.sync(b);

      expect(await _answerOn(b, _bakery), isNull);
    });

    test('a mesma resposta duas vezes grava um fato só', () async {
      await _memory(a).remember(key: _bakery, categoryId: 'bakery');

      final again = await _memory(a)
          .remember(key: _bakery, categoryId: 'bakery');

      expect(again, isFalse);
      final book = await a.read(ledgerProvider.future);
      expect(book.facts.whereType<AnswerLearned>(), hasLength(1));
    });

    test('esquecer o que não foi lembrado, ou lembrar sem dizer nada, não '
        'grava', () async {
      expect(await _memory(a).forget(_bakery), isFalse);
      expect(await _memory(a).remember(key: _bakery), isFalse);
      expect(
        await _memory(a).remember(key: 'a' * 81, categoryId: 'x'),
        isFalse,
      );

      final book = await a.read(ledgerProvider.future);
      expect(book.facts, isEmpty);
    });

    test('a resposta lembrada volta igual ao reabrir o app', () async {
      final store = MemoryEventStore();
      final codec = LedgerEventCodec(
        categoryOf: (id) => throw StateError('sem lançamento aqui'),
      );
      final first = ProviderContainer(
        overrides: testOverrides(
          journal: EventStoreLedgerJournal(store: store, codec: codec),
        ),
      );
      addTearDown(first.dispose);
      await first
          .read(answerMemoryProvider)
          .remember(
            key: StatementLineResolver.personKey('João P Silva'),
            treatment: LineTreatment.household,
            aboutPerson: true,
          );

      final reopened = ProviderContainer(
        overrides: testOverrides(
          journal: EventStoreLedgerJournal(store: store, codec: codec),
        ),
      );
      addTearDown(reopened.dispose);
      final answer = await _answerOn(
        reopened,
        StatementLineResolver.personKey('João P Silva'),
      );

      expect(answer?.treatment, LineTreatment.household);
      expect(answer?.aboutPerson, isTrue);
    });
  });
}
