import 'dart:convert';
import 'dart:typed_data';

import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/auth/application/device_directory.dart';
import 'package:cajui/src/features/auth/application/device_enrollment.dart';
import 'package:cajui/src/features/auth/application/device_invite.dart';
import 'package:cajui/src/features/auth/application/device_key_failure.dart';
import 'package:cajui/src/features/auth/application/device_key_store.dart';
import 'package:cajui/src/features/auth/application/known_device.dart';
import 'package:cajui/src/features/auth/application/server_session.dart';
import 'package:http/http.dart';

/// O que o servidor respondeu: o corpo em JSON, ou a **falha inteira**.
///
/// Leva o `ApiError`, e não só o código, porque o corpo de erro traz mais do
/// que o código: o `retryAfterSeconds` das classes *limite* e *ia*, que a
/// tela precisa para dizer quanto esperar. Antes o número se perdia aqui e a
/// tela mostrava 60 segundos fixos — um número inventado (BL-048).
typedef ApiOutcome = ({Map<String, Object?>? body, ApiError? failure});

/// O caminho até a API do Cajui, com a sessão do aparelho por baixo.
///
/// A sessão se renova sozinha: se ela venceu, este cliente pede um desafio ao
/// servidor, assina com a chave do Keystore e recomeça — sem pedir nada a
/// quem está usando o app. É a chave que prova quem somos, e ela não vence.
///
/// O cadastro (o código de 10 minutos) só é pedido uma vez, e só quando o
/// servidor ainda não conhece este aparelho.
final class CajuiApi implements DeviceEnrollment, DeviceDirectory {
  /// Cria o cliente para o endereço dado, assinando com a chave do aparelho.
  new({
    required this._baseUrl,
    required this._keys,
    Client? client,
    DateTime Function()? now,
  }) : _given = client,
       _now = now ?? DateTime.now;

  final Uri _baseUrl;
  final DeviceKeyStore _keys;

  /// A chave deste aparelho, para a raiz de composição ligá-la à porta.
  DeviceKeyStore get keys => _keys;
  final Client? _given;

  /// O cliente só nasce quando alguém vai mesmo falar com o servidor.
  ///
  /// No navegador, `HttpClient` do `dart:io` é um substituto que **estoura
  /// ao ser criado**. Construir a raiz de composição derrubava o app inteiro
  /// antes do primeiro quadro, e a tela nem chegava a existir.
  late final Client _client = _given ?? Client();
  final DateTime Function() _now;

  ServerSession? _session;

  /// Onde o servidor do Cajui mora. É um nome, e nunca um IP: o endereço da
  /// VM muda quando ela é parada e ligada de novo.
  static final Uri production = Uri.parse('https://api.cajui.example');

  /// Quanto tempo se espera pelo servidor antes de desistir.
  static const timeout = Duration(seconds: 20);

  /// Uma falha que nasceu **no aparelho** — sem rede, Keystore recusando —
  /// e por isso sem `ref`: não há ocorrência no registro do servidor.
  static ApiError _local(ErrorCode code) => ApiError(code: code, ref: '');

  /// Se há sessão aberta agora.
  bool get isOpen => _session?.isValidAt(_now()) ?? false;

  /// Abre a sessão **sem perguntar nada a ninguém**, se a chave do dia
  /// ainda estiver liberada, e diz se há sessão (BL-061). A sessão dura
  /// quinze minutos; a liberação da chave, um dia.
  Future<bool> openQuietly() async {
    if (isOpen || !_keys.exists) return isOpen;
    final outcome = await _withKey(() async {
      final probe = await _keys.signQuietly(Uint8List(1));
      if (probe.isNotEmpty) return await _open(quietly: true);
      return (body: null, failure: _local(ErrorCode.auth02));
    });
    return outcome.failure == null && isOpen;
  }

  /// Cadastra este aparelho com o código mostrado pelo servidor. Código
  /// errado, usado ou vencido volta como `E-AUTH-04` (RN-906).
  @override
  Future<ErrorCode?> enroll(String code, {required String name}) async {
    final outcome = await _withKey(() async {
      final publicKey = await _keys.publicKey();
      return await _post('/v1/auth/enroll', {
        'code': code.trim(),
        'deviceId': deviceIdOf(publicKey),
        'name': name,
        'publicKey': base64Encode(publicKey),
      });
    });
    return outcome.failure?.code;
  }

  @override
  Future<(List<KnownDevice>, ErrorCode?)> devices() async {
    final outcome = await authenticated(
      (token) => _send('GET', '/v1/devices', token: token),
    );
    if (outcome.body case final body?) {
      return (
        [
          for (final device in (body['devices'] as List?) ?? const [])
            if (device is Map) _device(device.cast<String, Object?>()),
        ],
        null,
      );
    }
    return (const <KnownDevice>[], outcome.failure?.code);
  }

  KnownDevice _device(Map<String, Object?> json) => KnownDevice(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Aparelho',
    isWeb: json['kind'] == 'web',
  );

  @override
  Future<(DeviceInvite?, ErrorCode?)> invite() => _invite('/v1/devices/codes');

  @override
  Future<(DeviceInvite?, ErrorCode?)> webInvite() =>
      _invite('/v1/devices/web-codes');

  Future<(DeviceInvite?, ErrorCode?)> _invite(String path) async {
    final outcome = await authenticated(
      (token) => post(path, const {}, token: token),
    );
    if (outcome.body case final body?) {
      return (
        DeviceInvite(
          code: body['code']! as String,
          seconds: body['expiresInSeconds'] as int? ?? 600,
        ),
        null,
      );
    }
    return (null, outcome.failure?.code);
  }

  @override
  Future<ErrorCode?> revoke(String id) async {
    final outcome = await authenticated(
      (token) => _send('DELETE', '/v1/devices/$id', token: token),
    );
    return outcome.failure?.code;
  }

  /// Faz [send] com a sessão aberta, abrindo-a se precisar. Uma única
  /// tentativa de reabrir: se o servidor recusar de novo, quem recusa é ele.
  Future<ApiOutcome> authenticated(
    Future<ApiOutcome> Function(String token) send,
  ) async {
    final opened = await _open();
    if (opened.failure != null) return opened;
    final outcome = await send(_session!.token);
    if (outcome.failure?.code != ErrorCode.auth03) return outcome;
    _session = null;
    final again = await _open();
    if (again.failure != null) return again;
    return await send(_session!.token);
  }

  /// Abre a sessão de **consulta** com o código que o celular mostrou
  /// (ADR-013). Não há chave nem assinatura: quem respondeu pela identidade
  /// foi o celular, ao emitir o código. O token fica só na memória e morre
  /// com a aba.
  Future<ErrorCode?> openWithCode(String code) async {
    final opened = await _post('/v1/auth/web', {'code': code.trim()});
    if (opened.body case final session?) {
      _session = ServerSession(
        token: session['token']! as String,
        expiresAt: _now().add(
          Duration(seconds: session['expiresInSeconds']! as int),
        ),
      );
    }
    return opened.failure?.code;
  }

  /// A sessão em vigor, ou uma nova, provada pela chave do aparelho.
  Future<ApiOutcome> _open({bool quietly = false}) async {
    if (isOpen) return (body: null, failure: null);
    // Sem chave — a web —, não há o que assinar: a sessão só entra pelo
    // código do celular, e enquanto ela não veio, o servidor é quem recusa.
    if (!_keys.exists) return (body: null, failure: _local(ErrorCode.auth03));
    return await _withKey(() async {
      final publicKey = await _keys.publicKey();
      final challenge = await _post('/v1/auth/challenge', {
        'deviceId': deviceIdOf(publicKey),
      });
      if (challenge.body case final issued?) {
        return await _sign(issued, quietly: quietly);
      }
      return challenge;
    });
  }

  /// Roda [body] traduzindo a recusa do Keystore em resposta do catálogo.
  ///
  /// Assinar é a única coisa daqui que pode falhar fora do Dart. Deixar esse
  /// erro subir travava a tela em "pensando", esperando algo que não vinha —
  /// foi o que o primeiro uso no aparelho mostrou.
  Future<ApiOutcome> _withKey(Future<ApiOutcome> Function() body) async {
    try {
      return await body();
    } on DeviceKeyFailure catch (failure) {
      return (body: null, failure: _local(failure.code));
    }
  }

  Future<ApiOutcome> _sign(
    Map<String, Object?> challenge, {
    required bool quietly,
  }) async {
    final nonce = base64Decode(challenge['nonce']! as String);
    final sign = quietly ? _keys.signQuietly : _keys.sign;
    final signature = await sign(nonce);
    // Caixa de diálogo fechada sem confirmar: não há o que mandar, e o
    // servidor não precisa saber que alguém desistiu.
    if (signature.isEmpty) {
      return (body: null, failure: _local(ErrorCode.auth02));
    }
    final opened = await _post('/v1/auth/session', {
      'challengeId': challenge['challengeId'],
      'signature': base64Encode(signature),
    });
    if (opened.body case final session?) {
      final seconds = session['expiresInSeconds']! as int;
      _session = ServerSession(
        token: session['token']! as String,
        expiresAt: _now().add(Duration(seconds: seconds)),
      );
    }
    return opened;
  }

  /// Um POST com corpo em JSON. Falha de rede vira `E-NET-01`: para quem
  /// usa, "sem servidor agora" é a mesma coisa, venha de onde vier.
  Future<ApiOutcome> post(
    String path,
    Map<String, Object?> body, {
    String? token,
  }) async => await _post(path, body, token: token);

  /// Um pedido qualquer com a sessão já aberta, para quem precisa de outro
  /// verbo além de POST.
  Future<ApiOutcome> send(
    String method,
    String path, {
    required String token,
    Map<String, Object?>? body,
  }) async => await _send(method, path, token: token, body: body);

  Future<ApiOutcome> _post(
    String path,
    Map<String, Object?> body, {
    String? token,
  }) => _send('POST', path, token: token, body: body);

  Future<ApiOutcome> _send(
    String method,
    String path, {
    String? token,
    Map<String, Object?>? body,
  }) async {
    try {
      final request = Request(method, _baseUrl.resolve(path))
        ..headers['content-type'] = 'application/json; charset=utf-8';
      if (token != null) request.headers['authorization'] = 'Bearer $token';
      if (body != null) request.body = jsonEncode(body);
      final response = await Response.fromStream(
        await _client.send(request).timeout(timeout),
      );
      return _read(response.statusCode, utf8.decode(response.bodyBytes));
    } on Object {
      return (body: null, failure: _local(ErrorCode.net01));
    }
  }

  /// Lê a resposta. A recusa vem pelo `ApiError` do contrato, e não por um
  /// formato imaginado aqui: **o corpo de erro tem o código dentro de
  /// `error`**, e ler na raiz fazia toda recusa do servidor — inclusive
  /// "este aparelho não é conhecido" — chegar como falha sem nome.
  ApiOutcome _read(int status, String text) {
    final decoded = text.isEmpty ? null : jsonDecode(text);
    final json = decoded is Map ? decoded.cast<String, Object?>() : null;
    if (status >= 200 && status < 300) {
      return (body: json ?? const <String, Object?>{}, failure: null);
    }
    if (json == null) return (body: null, failure: _local(ErrorCode.srv01));
    return (body: null, failure: ApiError.fromJson(json));
  }
}
