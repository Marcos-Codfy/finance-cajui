import 'dart:typed_data';

import 'package:cajui/src/features/auth/application/device_key_store.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/infrastructure/remote_ledger_journal.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_server.dart';

/// Uma chave que assina devolvendo a mensagem: quem confere é o servidor, e
/// aqui ele é o dublê.
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

Map<String, Object?> _entry({String id = 'e1', int cents = 8600}) => {
  'id': id,
  'description': 'Mercado',
  'amountCents': cents,
  'occurredOn': '2026-09-12',
  'categoryId': 'groceries',
  'paymentLines': [
    {'paymentMethodId': 'pix', 'kind': 'pix', 'amountCents': cents},
  ],
};

const Map<String, Object?> _plan = {
  'cashIncomeCents': 320000,
  'debtInstallmentsCents': 0,
  'fixed': <Object?>[],
  'variables': <Object?>[],
};

void main() {
  late FakeServer server;
  late RemoteLedgerJournal journal;

  setUp(() async {
    server = await FakeServer.start();
    addTearDown(server.stop);
    final api = CajuiApi(baseUrl: server.baseUrl, keys: _FakeKeys());
    journal = RemoteLedgerJournal(
      api,
      categoryOf: DefaultCatalog.emptyBook.categoryOf,
    );
  });

  group('ADR-013 · a consulta lê o livro do servidor', () {
    test('os lançamentos do servidor viram fatos do livro', () async {
      server.bodies['/v1/entries'] = {
        'entries': [_entry(), _entry(id: 'e2', cents: 1500)],
      };
      server.bodies['/v1/plan'] = const {'cashIncomeCents': 0};

      final events = await journal.readAll();

      expect(events.whereType<EntryRecorded>(), hasLength(2));
      expect(
        events.whereType<EntryRecorded>().first.entry.amount,
        const Money.fromCents(8600),
      );
    });

    test('BL-049 · o plano desce junto, e vem antes dos lançamentos', () async {
      server.bodies['/v1/entries'] = {
        'entries': [_entry()],
      };
      server.bodies['/v1/plan'] = _plan;

      final events = await journal.readAll();

      expect(events.first, isA<PlanDefined>());
      expect(
        (events.first as PlanDefined).setup.cashIncome,
        const Money.fromCents(320000),
      );
    });

    test('servidor sem plano não inventa um fato de plano vazio', () async {
      server.bodies['/v1/entries'] = const {'entries': <Object?>[]};
      server.bodies['/v1/plan'] = const {'cashIncomeCents': 0};

      final events = await journal.readAll();

      expect(events, isEmpty);
    });

    test('lançamento que este app não sabe reconstruir é pulado, e não '
        'derruba a tela inteira', () async {
      server.bodies['/v1/entries'] = {
        'entries': [
          {..._entry(), 'categoryId': 'categoria-que-nao-existe'},
          _entry(id: 'e2', cents: 1500),
        ],
      };
      server.bodies['/v1/plan'] = const {'cashIncomeCents': 0};

      final events = await journal.readAll();

      expect(events.whereType<EntryRecorded>(), hasLength(1));
      expect(events.whereType<EntryRecorded>().single.entry.id, 'e2');
    });

    test(
      'BL-060 · o crédito do vale desce, e o saldo aparece na consulta',
      () async {
        server.bodies['/v1/entries'] = const {'entries': <Object?>[]};
        server.bodies['/v1/plan'] = const {'cashIncomeCents': 0};
        server.bodies['/v1/income'] = const {
          'receipts': [
            {
              'id': 'r1',
              'sourceId': 'salario',
              'tender': 'mealVoucher',
              'amountCents': 50000,
              'receivedOn': '2026-09-05',
            },
          ],
          'voucherAdjustments': [
            {
              'id': 'a1',
              'adjustmentCents': -790,
              'on': '2026-09-20',
              'reason': 'o cartão mostrava outro saldo',
            },
          ],
        };

        final events = await journal.readAll();
        final book = events.fold(
          DefaultCatalog.emptyBook,
          (livro, event) => livro.apply(event),
        );

        expect(book.voucher.balance, const Money.fromCents(49210));
      },
    );

    test('T-12 · a consulta não grava: gravar estoura aqui', () {
      expect(
        () => journal.append(
          EntryCancelled(
            id: 'x',
            entryId: 'e1',
            on: LocalDate(2026, 9, 22),
            reason: 'lancei errado',
          ),
        ),
        throwsStateError,
      );
    });

    test('servidor fora do ar devolve livro vazio, e não uma tela de '
        'erro em branco', () async {
      await server.stop();

      expect(await journal.readAll(), isEmpty);
    });
  });
}
