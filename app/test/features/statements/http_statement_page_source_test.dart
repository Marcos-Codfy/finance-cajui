import 'dart:typed_data';

import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/auth/application/device_key_store.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';
import 'package:cajui/src/features/statements/infrastructure/http_statement_page_source.dart';
import 'package:domain/domain.dart';
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

const _path = '/v1/statements/read-part';

const _request = StatementPageRequest(
  lines: ['05/10 PIX ENVIADO [NOME] 150,00'],
  page: 2,
  pageCount: 7,
  period: BudgetMonth(2026, 10),
);

void main() {
  late FakeServer server;
  late FakeHouseholdKey keys;
  late HttpStatementPageSource source;

  setUp(() async {
    server = await FakeServer.start();
    addTearDown(server.stop);
    keys = FakeHouseholdKey();
    source = HttpStatementPageSource(
      CajuiApi(
        baseUrl: server.baseUrl,
        keys: keys,
        identity: _FakeIdentity(),
        client: server.client,
      ),
    );
  });

  group('ADR-030 · a página vai ao servidor com a chave da casa', () {
    test(
      'o pedido sobe como o contrato diz, e a resposta volta lida',
      () async {
        server.bodies[_path] = const StatementPageReply(
          movements: [
            StatementMovement(
              sourceLine: 1,
              day: 5,
              month: 10,
              description: 'Pix',
              amount: Money.fromCents(15000),
              categoryId: 'inventada',
            ),
          ],
          period: BudgetMonth(2026, 10),
        ).toJson();

        final outcome = await source.read(
          _request,
          knowsCategory: (id) => id == 'groceries',
        );

        final sent = server.requests.single;
        expect(sent.path, _path);
        expect(sent.authorization, 'Bearer ${keys.key}');
        expect(sent.body['lines'], _request.lines);
        expect(sent.body['period'], '2026-10');
        final movement = outcome.reply!.movements.single;
        expect(movement.amount, const Money.fromCents(15000));
        expect(movement.categoryId, isNull, reason: 'a lista é fechada');
        expect(outcome.failure, isNull);
      },
    );

    test('sem a chave da casa, nem tenta: E-AUTH-03', () async {
      keys.key = null;

      final outcome = await source.read(_request, knowsCategory: (_) => true);

      expect(server.requests, isEmpty);
      expect(outcome.failure, ErrorCode.auth03);
    });

    test('a recusa do servidor volta com o código do catálogo', () async {
      server.refuseWith(ErrorCode.ai04, status: 502);

      final outcome = await source.read(_request, knowsCategory: (_) => true);

      expect(outcome.reply, isNull);
      expect(outcome.failure, ErrorCode.ai04);
    });
  });
}
