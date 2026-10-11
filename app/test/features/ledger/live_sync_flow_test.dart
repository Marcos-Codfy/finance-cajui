import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_downlink.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_journal.dart';
import 'package:cajui/src/features/ledger/application/server_head.dart';
import 'package:cajui/src/features/ledger/infrastructure/no_ledger_uplink.dart';
import 'package:cajui/src/features/ledger/presentation/sync_on_resume.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_uplink.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/test_scope.dart';

/// Um topo de servidor que o teste move.
final class _Head implements ServerHead {
  int? seq = 5;
  int asked = 0;

  @override
  Future<int?> ledgerSeq() async {
    asked++;
    return seq;
  }
}

/// O livro do servidor: na web é o próprio livro, e é também a descida.
/// Conta as leituras; com [offline], não responde.
final class _ServerBook implements LedgerJournal, LedgerDownlink {
  List<LedgerEvent> events = const [];
  int reads = 0;
  bool offline = false;

  @override
  Future<List<LedgerEvent>> readAll() async => events;

  @override
  Future<LedgerSnapshot?> snapshot() async {
    reads++;
    return offline ? null : (events: events, cancelled: const <String>{});
  }

  @override
  Future<void> append(LedgerEvent event) =>
      throw StateError('a consulta não grava');
}

/// Uma padaria lançada no outro celular.
EntryRecorded _bakery() => EntryRecorded(
  Entry.create(
    id: 'padaria',
    description: 'Padaria',
    amount: const Money.fromCents(1850),
    occurredOn: testToday,
    category: DefaultCatalog.emptyBook.categoryOf('bakery'),
    paymentLines: [
      DefaultCatalog.emptyBook
          .methodOf('pix')
          .line(const Money.fromCents(1850)),
    ],
    today: testToday,
  ).valueOrNull!,
);

Future<ProviderContainer> _open(
  WidgetTester tester, {
  required _Head head,
  required _ServerBook server,
  required bool web,
}) async {
  final uplink = FakeUplink()..session = true;
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(
        journal: web ? server : MemoryLedgerJournal(),
        uplink: web ? const NoLedgerUplink() : uplink,
        downlink: server,
        head: head,
      ),
      child: const SyncOnResume(child: SizedBox.shrink()),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(SizedBox)));
}

Future<void> _twentySeconds(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 20));
  await tester.pumpAndSettle();
}

void main() {
  late _Head head;
  late _ServerBook server;

  setUp(() {
    head = _Head();
    server = _ServerBook();
  });

  group('ADR-024 · no celular', () {
    testWidgets('o topo parado não desce nada; o que andou desce em até 20 '
        'segundos, sem ninguém tocar em nada', (tester) async {
      await _open(tester, head: head, server: server, web: false);
      final atStart = server.reads;

      await _twentySeconds(tester);
      expect(server.reads, atStart, reason: 'nada mudou no servidor');

      head.seq = 6;
      await _twentySeconds(tester);
      expect(server.reads, atStart + 1);
    });

    testWidgets('no fundo, para de perguntar; de volta à frente, pergunta e '
        'sincroniza na hora', (tester) async {
      await _open(tester, head: head, server: server, web: false);
      final asked = head.asked;
      final reads = server.reads;

      const [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ].forEach(tester.binding.handleAppLifecycleStateChanged);
      await tester.pump(const Duration(minutes: 2));
      expect(head.asked, asked, reason: 'celular no bolso não pergunta');

      const [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ].forEach(tester.binding.handleAppLifecycleStateChanged);
      await tester.pumpAndSettle();
      expect(head.asked, asked + 1);
      expect(server.reads, reads + 1, reason: 'a volta sobe e desce');
    });
  });

  group('ADR-024 · na web', () {
    testWidgets('o lançamento feito no celular aparece sozinho, sem a tela '
        'voltar ao "carregando"', (tester) async {
      final container = await _open(
        tester,
        head: head,
        server: server,
        web: true,
      );
      final seen = <AsyncValue<LedgerBook>>[];
      container.listen(ledgerProvider, (_, next) => seen.add(next));

      server.events = [_bakery()];
      head.seq = 6;
      await _twentySeconds(tester);

      final book = container.read(ledgerProvider).value!;
      expect(book.entries.single.description, 'Padaria');
      expect(seen.whereType<AsyncLoading<LedgerBook>>(), isEmpty);
    });

    testWidgets('sem resposta no meio da releitura, o que está na tela '
        'fica', (tester) async {
      server.events = [_bakery()];
      final container = await _open(
        tester,
        head: head,
        server: server,
        web: true,
      );

      server.offline = true;
      head.seq = 6;
      await _twentySeconds(tester);

      expect(container.read(ledgerProvider).value!.entries, hasLength(1));
    });
  });

  test('no celular, reler pelo servidor não faz nada: o livro de lá é o '
      'registro do aparelho', () async {
    final phone = ProviderContainer(
      overrides: testOverrides(downlink: server..events = [_bakery()]),
    );
    addTearDown(phone.dispose);
    await phone.read(ledgerProvider.future);

    final reloaded = await phone.read(ledgerProvider.notifier).reload();

    expect(reloaded, isFalse);
    expect((await phone.read(ledgerProvider.future)).entries, isEmpty);
  });
}
