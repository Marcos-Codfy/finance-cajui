import 'dart:convert';
import 'dart:typed_data';

import 'package:server/src/app.dart';
import 'package:server/src/auth/code_routes.dart';
import 'package:server/src/auth/household_key.dart';
import 'package:server/src/auth/session_book.dart';
import 'package:server/src/auth/totp.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'support/fixed_clock.dart';
import 'support/test_app.dart';

/// O segredo da RFC 6238, apêndice B: "12345678901234567890" em ASCII.
final Uint8List _rfcSecret = Uint8List.fromList(
  utf8.encode('12345678901234567890'),
);

/// O passo de 30 segundos da hora do relógio dos testes.
int get _step => const FixedClock().now().millisecondsSinceEpoch ~/ 1000 ~/ 30;

Future<(int, Map<String, Object?>)> _enter(TestApp server, String code) =>
    server.call('POST', '/v1/auth/code', body: {'code': code});

void main() {
  group('RFC 6238 · o código do autenticador', () {
    test(
      'os vetores da RFC: os seis últimos dígitos de 94287082 e 07081804',
      () {
        final totp = Totp(_rfcSecret);

        expect(totp.codeAt(59 ~/ 30), '287082');
        expect(totp.codeAt(1111111109 ~/ 30), '081804');
      },
    );

    test('base32 com espaço e minúscula é o mesmo segredo', () {
      // "12345678901234567890" em base32.
      final bytes = Totp.base32('gezd gnbv gy3t qojq gezd gnbv gy3t qojq');

      expect(bytes, _rfcSecret);
      expect(Totp.base32('não é base32!'), isNull);
    });

    test('vale o passo de agora e os vizinhos, e cada um só uma vez', () {
      final totp = Totp(_rfcSecret);
      final now = DateTime.utc(2026, 10, 11, 12);
      final step = now.millisecondsSinceEpoch ~/ 1000 ~/ 30;

      expect(totp.accepts(totp.codeAt(step - 1), now), isTrue);
      expect(totp.accepts(totp.codeAt(step - 1), now), isFalse);
      expect(totp.accepts(totp.codeAt(step + 2), now), isFalse);
      expect(totp.accepts('12345', now), isFalse);
    });
  });

  group('ADR-027 · a web entra com o código', () {
    test(
      'o código certo abre uma sessão que lê e conversa, e não grava',
      () async {
        final server = await TestApp.start(totp: Totp(_rfcSecret));

        final (status, body) = await _enter(
          server,
          Totp(_rfcSecret).codeAt(_step),
        );
        final token = body['token']! as String;
        final (read, _) = await server.call('GET', '/v1/entries', token: token);
        final (write, _) = await server.call(
          'POST',
          '/v1/categories',
          body: const {'id': 'x'},
          token: token,
        );

        expect(status, 200);
        expect(read, 200);
        expect(write, 403);
      },
    );

    test(
      'cinco códigos errados fecham a porta, e nem o certo entra depois',
      () async {
        final server = await TestApp.start(totp: Totp(_rfcSecret));

        for (var i = 0; i < CodeRoutes.maxFailures; i++) {
          final (status, _) = await _enter(server, '000000');
          expect(status, 401);
        }
        final (locked, _) = await _enter(
          server,
          Totp(_rfcSecret).codeAt(_step),
        );

        expect(locked, 401);
      },
    );

    test('sem o segredo no servidor, código nenhum entra', () async {
      final server = await TestApp.start();

      final (status, _) = await _enter(server, '123456');

      expect(status, 401);
    });

    test('a sessão do código sobrevive ao servidor reiniciar, e o registro '
        'guarda só o hash', () async {
      final server = await TestApp.start(totp: Totp(_rfcSecret));
      final (_, body) = await _enter(server, Totp(_rfcSecret).codeAt(_step));
      final token = body['token']! as String;

      final restarted = App(
        store: server.store,
        clock: const FixedClock(),
        log: (_) {},
        sessions: SessionBook(now: const FixedClock().now),
        householdKey: HouseholdKey(TestApp.key),
      );
      final response = await restarted.handler(
        Request(
          'GET',
          Uri.parse('http://localhost/v1/entries'),
          headers: {'authorization': 'Bearer $token'},
        ),
      );

      expect(response.statusCode, 200);
      final saved = server.store.events.where(
        (event) => event.type == SessionBook.openedType,
      );
      expect(jsonEncode(saved.single.payload), isNot(contains(token)));
    });
  });
}
