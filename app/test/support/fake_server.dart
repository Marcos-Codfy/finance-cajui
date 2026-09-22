import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:http/http.dart';

/// O que o app mandou: o caminho, o corpo e o portador.
typedef SentRequest = ({
  String path,
  Map<String, Object?> body,
  String authorization,
});

/// Um servidor de verdade, de mentira: fala HTTP no `localhost` e guarda o
/// que recebeu.
///
/// É um servidor real, e não um dublê do cliente HTTP, de propósito: assim o
/// teste exercita cabeçalho, corpo, código de status e o caminho inteiro do
/// `CajuiApi` — inclusive a falha de rede, que é só desligá-lo.
final class FakeServer {
  new _(this._server);

  /// Sobe o servidor numa porta livre.
  static Future<FakeServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fake = FakeServer._(server);
    unawaited(fake._listen());
    return fake;
  }

  final HttpServer _server;

  /// Tudo o que chegou, na ordem.
  final List<SentRequest> requests = [];

  ErrorCode? _refusal;
  int _refusalStatus = 401;
  bool _onlyOnce = false;

  /// O corpo que o assistente devolve. O teste troca à vontade.
  Map<String, Object?> answer = const {
    'text': 'tudo certo',
    'outOfScope': false,
    'fallback': false,
    'sources': <Object?>[],
  };

  /// O endereço para o cliente.
  Uri get baseUrl => Uri.parse('http://127.0.0.1:${_server.port}');

  /// Um cliente comum: o teste não finge rede, ele usa rede.
  Client get client => Client();

  /// Os caminhos pedidos, na ordem.
  List<String> get paths => [for (final request in requests) request.path];

  /// Respostas por caminho, para o teste montar o servidor de que precisa.
  /// Caminho que não estiver aqui continua caindo em [answer].
  final Map<String, Map<String, Object?>> bodies = {};

  /// Passa a recusar tudo com [code].
  void refuseWith(ErrorCode code, {int status = 401}) {
    _refusal = code;
    _refusalStatus = status;
    _onlyOnce = false;
  }

  /// Recusa **a próxima** com [code], e depois volta ao normal.
  void refuseOnceWith(ErrorCode code, {int status = 401}) {
    refuseWith(code, status: status);
    _onlyOnce = true;
  }

  /// Desliga: é como o teste simula ficar sem servidor.
  Future<void> stop() => _server.close(force: true);

  Future<void> _listen() async {
    await for (final request in _server) {
      final text = await utf8.decoder.bind(request).join();
      final decoded = text.isEmpty
          ? const <String, Object?>{}
          : jsonDecode(text);
      requests.add((
        path: request.uri.path,
        body: decoded is Map
            ? decoded.cast<String, Object?>()
            : const <String, Object?>{},
        authorization: request.headers.value('authorization') ?? '',
      ));
      _reply(request);
      await request.response.close();
    }
  }

  void _reply(HttpRequest request) {
    final refusal = _refusal;
    // O cadastro nunca é recusado por engano: quem recusa é a regra do teste.
    if (refusal != null && !request.uri.path.endsWith('/challenge')) {
      if (_onlyOnce) _refusal = null;
      request.response.statusCode = _refusalStatus;
      // O corpo de erro sai do **mesmo** `ApiError` que o servidor usa. Já
      // foi escrito à mão aqui, no formato que o app imaginava, e o teste
      // passou a confirmar a suposição em vez do servidor: no aparelho,
      // toda recusa chegava como falha sem nome.
      request.response.write(
        jsonEncode(ApiError(code: refusal, ref: 'teste').toJson()),
      );
      return;
    }
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(_bodyFor(request.uri.path)));
  }

  Map<String, Object?> _bodyFor(String path) => switch (bodies[path]) {
    final resposta? => resposta,
    _ => _defaultBodyFor(path),
  };

  Map<String, Object?> _defaultBodyFor(String path) => switch (path) {
    '/v1/auth/enroll' => {'deviceId': 'aparelho'},
    '/v1/auth/challenge' => {
      'challengeId': 'desafio',
      'nonce': base64Encode([7, 7, 7]),
    },
    '/v1/auth/session' => {'token': 'portador', 'expiresInSeconds': 900},
    _ => answer,
  };
}
