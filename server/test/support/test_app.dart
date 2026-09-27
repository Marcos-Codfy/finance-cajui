import 'dart:convert';
import 'dart:io';

import 'package:persistence/persistence.dart';
import 'package:server/src/app.dart';
import 'package:server/src/assistant/assistant_service.dart';
import 'package:server/src/auth/session_book.dart';
import 'package:server/src/auth/session_scope.dart';
import 'package:server/src/http/rate_limiter.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'fixed_clock.dart';

/// O servidor inteiro, montado em memória sobre uma pasta temporária: os
/// testes exercitam o `Pipeline` de verdade, sem abrir porta.
final class TestApp {
  new _(this.app, this.store, this.data, this.logs);

  /// O servidor.
  final App app;

  /// O registro de eventos por baixo dele.
  final FileEventStore store;

  /// A pasta de dados.
  final Directory data;

  /// Tudo o que o servidor registrou.
  final List<String> logs;

  /// Sobe um servidor novo. [rateLimiter] permite apertar o limite.
  static Future<TestApp> start({
    RateLimiter? rateLimiter,
    AssistantService? Function(FileEventStore store)? assistant,
  }) async {
    final data = Directory.systemTemp.createTempSync('cajui-server-');
    addTearDown(() => data.deleteSync(recursive: true));
    final store = await FileEventStore.open(
      data,
      AesGcmRecordCipher(List.generate(32, (i) => i)),
    );
    final logs = <String>[];
    final app = App(
      store: store,
      dataDirectory: data,
      clock: const FixedClock(),
      log: logs.add,
      sessions: SessionBook(),
      rateLimiter: rateLimiter,
      assistant: assistant?.call(store),
    );
    return TestApp._(app, store, data, logs);
  }

  /// Um token de sessão válido, sem passar pela biometria.
  String token({SessionScope scope = SessionScope.device}) =>
      app.sessions.open('test-device', scope: scope);

  /// Faz uma requisição crua e devolve a resposta inteira, cabeçalhos
  /// inclusive — é o que o teste de origem cruzada precisa ver.
  Future<Response> send(
    String method,
    String path, {
    Map<String, String> headers = const {},
  }) async => await app.handler(
    Request(method, Uri.parse('http://localhost$path'), headers: headers),
  );

  /// Faz uma requisição e devolve o status e o corpo, já lido como JSON.
  Future<(int, Map<String, Object?>)> call(
    String method,
    String path, {
    Object? body,
    String? token,
  }) async {
    final response = await app.handler(
      Request(
        method,
        Uri.parse('http://localhost$path'),
        body: body == null ? null : jsonEncode(body),
        headers: {if (token != null) 'authorization': 'Bearer $token'},
      ),
    );
    final text = await response.readAsString();
    final json = text.isEmpty ? <String, Object?>{} : jsonDecode(text);
    return (response.statusCode, json as Map<String, Object?>);
  }
}
