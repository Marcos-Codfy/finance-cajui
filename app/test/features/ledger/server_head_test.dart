import 'dart:typed_data';

import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/auth/application/device_key_store.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/infrastructure/cajui_server_head.dart';
import 'package:cajui/src/features/ledger/infrastructure/remote_ledger_journal.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_household_key.dart';
import '../../support/fake_server.dart';

/// A identidade do aparelho de teste: uma chave pública qualquer.
final class _FakeIdentity implements DeviceKeyStore {
  @override
  bool get exists => true;

  @override
  Future<Uint8List> publicKey() async => Uint8List.fromList([1, 2, 3, 4]);
}

void main() {
  late FakeServer server;
  late CajuiApi api;

  setUp(() async {
    server = await FakeServer.start();
    addTearDown(server.stop);
    api = CajuiApi(
      baseUrl: server.baseUrl,
      keys: FakeHouseholdKey(),
      identity: _FakeIdentity(),
    );
  });

  group('ADR-024 · o topo do registro pela API', () {
    test('lê o ledgerSeq, com a chave da casa', () async {
      server.bodies['/v1/head'] = const {'seq': 12, 'ledgerSeq': 9};

      expect(await CajuiServerHead(api).ledgerSeq(), 9);
      expect(server.requests.single.authorization, startsWith('Bearer '));
    });

    test('servidor anterior ao ledgerSeq: vale o seq', () async {
      server.bodies['/v1/head'] = const {'seq': 12};

      expect(await CajuiServerHead(api).ledgerSeq(), 12);
    });

    test('ADR-027 · credencial recusada é esquecida: a web volta à entrada '
        'quando a sessão do código vence', () async {
      final keys = FakeHouseholdKey('token-da-sessao-vencida');
      final expired = CajuiApi(
        baseUrl: server.baseUrl,
        keys: keys,
        identity: _FakeIdentity(),
      );
      server.refuseWith(ErrorCode.auth03);

      await CajuiServerHead(expired).ledgerSeq();

      expect(keys.key, isNull);
    });

    test('recusa por outro motivo não tira ninguém da web', () async {
      final keys = FakeHouseholdKey('token-que-vale');
      final valid = CajuiApi(
        baseUrl: server.baseUrl,
        keys: keys,
        identity: _FakeIdentity(),
      );
      server.refuseWith(ErrorCode.rate01, status: 429);

      await CajuiServerHead(valid).ledgerSeq();

      expect(keys.key, 'token-que-vale');
    });

    test('sem servidor, "não sei" — e não zero', () async {
      await server.stop();

      expect(await CajuiServerHead(api).ledgerSeq(), isNull);
    });
  });

  group('ADR-024 · a leitura do servidor é inteira ou nenhuma', () {
    late RemoteLedgerJournal journal;

    setUp(() {
      journal = RemoteLedgerJournal(
        api,
        categoryOf: DefaultCatalog.emptyBook.categoryOf,
      );
      server.bodies['/v1/entries'] = const {'entries': <Object?>[]};
      server.bodies['/v1/plan'] = const {'cashIncomeCents': 0};
    });

    test('o cartão desce com o carimbo da versão que o servidor tem', () async {
      server.bodies['/v1/cards'] = {
        'cards': [
          CatalogVersion.stamped({
            'id': 'card-casa',
            'name': 'Cartão da casa',
            'closingDay': 28,
            'dueDay': 5,
            'creditLimitCents': 650000,
          }, DateTime.utc(2026, 9, 18, 18)),
        ],
      };

      final snapshot = await journal.snapshot();

      final card = snapshot!.events.whereType<CardDefined>().single;
      expect(card.card.closingDay, 28);
      expect(card.definedAt, DateTime.utc(2026, 9, 18, 18));
    });

    test('uma parte que não respondeu é "não sei": nem a web mostra meio '
        'livro, nem o celular desce meio livro', () async {
      server.failing.add('/v1/plan');

      expect(await journal.snapshot(), isNull);
      expect(await journal.readAll(), isEmpty);
    });
  });
}
