import 'package:server/src/ledger/ledger_state.dart';
import 'package:test/test.dart';

import 'support/sample_bodies.dart';
import 'support/test_app.dart';

/// O cartão da casa, como o celular o manda, com o carimbo [at].
Map<String, Object?> _card({
  int closingDay = 25,
  int limitCents = 500000,
  String? at,
}) => {
  'id': 'card-1',
  'name': 'Cartão da casa',
  'closingDay': closingDay,
  'dueDay': 5,
  'creditLimitCents': limitCents,
  'definedAt': ?at,
};

/// Segunda e sexta da semana do cenário, antes do "agora" do relógio fixo.
const _monday = '2026-09-14T09:00:00.000Z';
const _friday = '2026-09-18T18:00:00.000Z';

void main() {
  late TestApp server;

  setUp(() async {
    server = await TestApp.start();
  });

  Future<(int, Map<String, Object?>)> post(
    String path,
    Map<String, Object?> body,
  ) => server.call('POST', path, body: body, token: server.token());

  Future<Map<String, Object?>> cardOnServer() async {
    final (_, body) = await server.call(
      'GET',
      '/v1/cards',
      token: server.token(),
    );
    return (body['cards']! as List<Object?>).single! as Map<String, Object?>;
  }

  group('E-CARD-01 · o dia do cartão que não existe', () {
    test('é recusa de regra (422), e não defeito do servidor (500)', () async {
      for (final day in [0, 32, 40]) {
        final (status, body) = await post('/v1/cards', _card(closingDay: day));

        final error = body['error']! as Map<String, Object?>;
        expect(status, 422, reason: 'dia $day');
        expect(error['code'], 'E-CARD-01');
        expect((error['detail']! as Map<String, Object?>)['day'], day);
      }
    });

    test('nada é gravado quando o dia é recusado', () async {
      final before = server.store.events.length;

      await post('/v1/cards', _card(closingDay: 40));

      expect(server.store.events.length, before);
    });
  });

  group('ADR-024 · o cartão editado atravessa', () {
    test('a edição mais nova grava e passa a valer, com o carimbo', () async {
      final (created, _) = await post('/v1/cards', _card(at: _monday));
      final (edited, _) = await post(
        '/v1/cards',
        _card(closingDay: 28, limitCents: 650000, at: _friday),
      );

      final card = await cardOnServer();
      expect(created, 201);
      expect(edited, 201, reason: 'antes voltava como repetida e sumia');
      expect(card['closingDay'], 28);
      expect(card['creditLimitCents'], 650000);
      expect(card['definedAt'], _friday);
    });

    test('a versão mais velha chegando depois não passa por cima', () async {
      await post('/v1/cards', _card(closingDay: 28, at: _friday));

      final (status, body) = await post('/v1/cards', _card(at: _monday));

      expect(status, 200);
      expect(body['kept'], isTrue);
      expect((await cardOnServer())['closingDay'], 28);
    });

    test('a mesma versão de novo não grava evento nenhum', () async {
      await post('/v1/cards', _card(at: _monday));
      final before = server.store.events.length;

      final (status, _) = await post('/v1/cards', _card(at: _friday));

      expect(status, 200, reason: 'mesmo conteúdo, só o carimbo mudou');
      expect(server.store.events.length, before);
    });

    test('T-40 · carimbo no futuro é recusado: travaria o cartão para '
        'sempre contra o outro celular', () async {
      final (status, body) = await post(
        '/v1/cards',
        _card(at: '9999-01-01T00:00:00.000Z'),
      );

      expect(status, 400);
      expect(errorOf(body)['code'], 'E-REQ-01');
    });

    test('o cartão gravado antes do carimbo conta como o mais velho', () async {
      final legacy = await TestApp.start(
        seed: (store) => store.append(
          id: 'card-card-1',
          type: LedgerState.cardDefined,
          payload: _card(closingDay: 10),
        ),
      );
      Future<(int, Map<String, Object?>)> postLegacy(Map<String, Object?> b) =>
          legacy.call('POST', '/v1/cards', body: b, token: legacy.token());

      final (edited, _) = await postLegacy(_card(closingDay: 28, at: _monday));
      final (stale, _) = await postLegacy(_card(closingDay: 12));

      final replayed = LedgerState(legacy.store.events);
      expect(edited, 201);
      expect(stale, 200, reason: 'sem carimbo não passa por cima de carimbo');
      expect(replayed.cards['card-1']!.closingDay, 28);
    });

    test('ADR-004 · reler o registro chega à mesma versão, mesmo com a mais '
        'velha gravada por último', () async {
      final legacy = await TestApp.start(
        seed: (store) async {
          await store.append(
            id: 'card-card-1-a',
            type: LedgerState.cardDefined,
            payload: _card(closingDay: 28, at: _friday),
          );
          await store.append(
            id: 'card-card-1-b',
            type: LedgerState.cardDefined,
            payload: _card(closingDay: 10, at: _monday),
          );
        },
      );

      expect(LedgerState(legacy.store.events).cards['card-1']!.closingDay, 28);
    });
  });

  group('ADR-024 · a categoria reagrupada atravessa', () {
    test('o bloco novo, mais novo pelo carimbo, passa a valer', () async {
      await post('/v1/categories', groceriesBody);

      final (status, _) = await post('/v1/categories', {
        ...groceriesBody,
        'groupId': 'household-food',
        'definedAt': _friday,
      });
      final (_, body) = await server.call(
        'GET',
        '/v1/categories',
        token: server.token(),
      );

      final groceries =
          (body['categories']! as List<Object?>).single!
              as Map<String, Object?>;
      expect(status, 201);
      expect(groceries['groupId'], 'household-food');
      expect(groceries['definedAt'], _friday);
    });

    test(
      'a categoria de antes, sem carimbo, não desfaz a reagrupada',
      () async {
        await post('/v1/categories', {
          ...groceriesBody,
          'groupId': 'household-food',
          'definedAt': _friday,
        });

        final (status, body) = await post('/v1/categories', groceriesBody);

        expect(status, 200);
        expect(body['kept'], isTrue);
        expect(
          LedgerState(server.store.events).categories['groceries']!.groupId,
          'household-food',
        );
      },
    );
  });
}
