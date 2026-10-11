import 'dart:convert';
import 'dart:io';

import 'package:persistence/persistence.dart';
import 'package:server/src/app.dart';
import 'package:server/src/assistant/assistant_service.dart';
import 'package:server/src/auth/household_key.dart';
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

  /// A chave da casa dos testes: fictícia, e do tamanho que a de verdade
  /// precisa ter.
  static const key = 'chave-ficticia-da-casa-de-teste';

  /// Sobe um servidor novo, com a chave da casa [key] — ou com
  /// [householdKey], quando o teste quer outra, e sem chave nenhuma com
  /// [keyless]. [rateLimiter] permite apertar o limite; [seed] grava
  /// eventos **antes** de o servidor subir, como um registro que já existia.
  static Future<TestApp> start({
    RateLimiter? rateLimiter,
    AssistantService? Function(FileEventStore store)? assistant,
    HouseholdKey? householdKey,
    bool keyless = false,
    Future<void> Function(FileEventStore store)? seed,
  }) async {
    final data = Directory.systemTemp.createTempSync('cajui-server-');
    addTearDown(() => data.deleteSync(recursive: true));
    final store = await FileEventStore.open(
      data,
      AesGcmRecordCipher(List.generate(32, (i) => i)),
    );
    await seed?.call(store);
    final logs = <String>[];
    final app = App(
      store: store,
      clock: const FixedClock(),
      log: logs.add,
      sessions: SessionBook(),
      rateLimiter: rateLimiter,
      assistant: assistant?.call(store),
      householdKey: keyless ? null : householdKey ?? HouseholdKey(key),
    );
    return TestApp._(app, store, data, logs);
  }

  /// Com o que o teste entra: a chave da casa, que lê e escreve (ADR-020).
  /// Só de leitura, uma sessão aberta direto no livro — nenhuma rota abre
  /// uma hoje, mas o escopo continua imposto no servidor (ADR-024).
  String token({SessionScope scope = SessionScope.device}) =>
      scope == SessionScope.device
      ? key
      : app.sessions.open('consulta', scope: scope);

  /// Faz uma requisição crua e devolve a resposta inteira, cabeçalhos
  /// inclusive — é o que o teste de origem cruzada precisa ver.
  Future<Response> send(
    String method,
    String path, {
    Map<String, String> headers = const {},
    Object? body,
  }) async => await app.handler(
    Request(
      method,
      Uri.parse('http://localhost$path'),
      headers: headers,
      body: body == null ? null : jsonEncode(body),
    ),
  );

  /// Faz uma requisição e devolve o status e o corpo, já lido como JSON.
  /// [headers] entram por cima do portador: é por aí que o teste diz de
  /// que aparelho vem a pergunta.
  Future<(int, Map<String, Object?>)> call(
    String method,
    String path, {
    Object? body,
    String? token,
    Map<String, String> headers = const {},
  }) async {
    final response = await app.handler(
      Request(
        method,
        Uri.parse('http://localhost$path'),
        body: body == null ? null : jsonEncode(body),
        headers: {
          if (token != null) 'authorization': 'Bearer $token',
          ...headers,
        },
      ),
    );
    final text = await response.readAsString();
    final json = text.isEmpty ? <String, Object?>{} : jsonDecode(text);
    return (response.statusCode, json as Map<String, Object?>);
  }
}
