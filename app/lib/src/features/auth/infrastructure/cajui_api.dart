import 'dart:convert';

import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/auth/application/device_identity.dart';
import 'package:cajui/src/features/auth/application/device_key_store.dart';
import 'package:cajui/src/features/auth/application/household_key_store.dart';
import 'package:http/http.dart';

/// O que o servidor respondeu: o corpo em JSON, ou a **falha inteira**.
///
/// Leva o `ApiError`, e não só o código, porque o corpo de erro traz mais do
/// que o código: o `retryAfterSeconds` das classes *limite* e *ia*, que a
/// tela precisa para dizer quanto esperar (BL-048).
typedef ApiOutcome = ({Map<String, Object?>? body, ApiError? failure});

/// O caminho até a API do Cajui, com a chave da casa por baixo (ADR-020).
///
/// Toda chamada leva a chave no cabeçalho e o nome deste aparelho em outro.
/// Não há sessão para abrir nem renovar: a chave não vence, e sem ela não
/// há com quem falar — a recusa é a do catálogo, antes de qualquer rede.
final class CajuiApi {
  /// Cria o cliente para o endereço dado.
  new({
    required this._baseUrl,
    required this._keys,
    required this._identity,
    Client? client,
  }) : _given = client;

  final Uri _baseUrl;
  final HouseholdKeyStore _keys;
  final DeviceKeyStore _identity;
  final Client? _given;

  /// O cliente só nasce quando alguém vai mesmo falar com o servidor.
  ///
  /// No navegador, `HttpClient` do `dart:io` é um substituto que **estoura
  /// ao ser criado**. Construir a raiz de composição derrubava o app inteiro
  /// antes do primeiro quadro, e a tela nem chegava a existir.
  late final Client _client = _given ?? Client();

  /// Onde o servidor mora: um nome, nunca um IP — o da VM muda ao religar.
  ///
  /// Entra na compilação (`--dart-define=CAJUI_API_URL=https://…`) e **não é
  /// versionado**. Sem ele, o app aponta para um endereço de exemplo e só
  /// funciona sozinho no aparelho, sem sincronizar.
  static final Uri production = Uri.parse(
    const String.fromEnvironment(
      'CAJUI_API_URL',
      defaultValue: 'https://api.cajui.example',
    ),
  );

  /// Quanto tempo se espera pelo servidor antes de desistir.
  static const timeout = Duration(seconds: 20);

  /// Quanto se espera quando a IA olha fotos: subir até três imagens pela
  /// rede do celular e ler um extrato inteiro leva mais do que um pedido
  /// comum. Fica acima do limite do servidor, para a resposta dele — mesmo
  /// a de "não deu" — chegar antes de o aparelho desistir.
  static const readingTimeout = Duration(seconds: 50);

  /// O cabeçalho em que o aparelho diz quem é. Não prova nada — quem prova
  /// é a chave —; separa a conversa de cada celular com o assistente.
  static const deviceHeader = 'x-cajui-device';

  /// Uma falha nascida **no aparelho** — sem rede, sem chave —, sem `ref`:
  /// não há ocorrência no registro do servidor.
  static ApiError _local(ErrorCode code) => ApiError(code: code, ref: '');

  /// Se este aparelho tem a chave da casa. Sem ela não há servidor.
  bool get hasKey => _keys.read() != null;

  /// O nome deste aparelho, uma vez só: a chave pública do Keystore leva
  /// um instante para sair do chip, e não precisa sair a cada chamada.
  late final Future<String> _deviceId = _resolveDeviceId();

  Future<String> _resolveDeviceId() async {
    if (!_identity.exists) return 'web';
    try {
      final key = await _identity.publicKey();
      return key.isEmpty ? 'celular' : DeviceIdentity.of(key);
    } on Object {
      // Keystore recusando não é motivo para não sincronizar: o aparelho
      // fala com o servidor com um nome genérico.
      return 'celular';
    }
  }

  /// Faz [send] com a chave da casa. Sem chave, a recusa é local e
  /// imediata: `E-AUTH-03`, o mesmo que o servidor diria.
  Future<ApiOutcome> authenticated(
    Future<ApiOutcome> Function(String token) send,
  ) async {
    final key = _keys.read();
    if (key == null) return (body: null, failure: _local(ErrorCode.auth03));
    return await send(key);
  }

  /// Um POST com corpo em JSON. Falha de rede vira `E-NET-01`: para quem
  /// usa, "sem servidor agora" é a mesma coisa, venha de onde vier.
  Future<ApiOutcome> post(
    String path,
    Map<String, Object?> body, {
    String? token,
    Duration waitFor = timeout,
  }) => _send('POST', path, token: token, body: body, waitFor: waitFor);

  /// Um pedido em qualquer verbo.
  Future<ApiOutcome> send(
    String method,
    String path, {
    required String token,
    Map<String, Object?>? body,
  }) => _send(method, path, token: token, body: body);

  Future<ApiOutcome> _send(
    String method,
    String path, {
    String? token,
    Map<String, Object?>? body,
    Duration waitFor = timeout,
  }) async {
    try {
      final request = Request(method, _baseUrl.resolve(path))
        ..headers['content-type'] = 'application/json; charset=utf-8'
        ..headers[deviceHeader] = await _deviceId;
      if (token != null) request.headers['authorization'] = 'Bearer $token';
      if (body != null) request.body = jsonEncode(body);
      final response = await Response.fromStream(
        await _client.send(request).timeout(waitFor),
      );
      if (response.statusCode == 401) await _rejected(token);
      return _read(response.statusCode, utf8.decode(response.bodyBytes));
    } on Object {
      return (body: null, failure: _local(ErrorCode.net01));
    }
  }

  /// O servidor recusou [token]: se é o que está guardado, ele é
  /// esquecido, e a web volta à tela de entrada — a sessão do código vence
  /// em trinta dias (ADR-027), e ficar com ela era ficar numa web vazia sem
  /// saída. No celular a chave vem compilada, e esquecer não faz nada.
  Future<void> _rejected(String? token) async {
    if (token != null && token == _keys.read()) await _keys.forget();
  }

  /// Lê a resposta. A recusa vem pelo `ApiError` do contrato, e não por um
  /// formato imaginado aqui: **o corpo de erro tem o código dentro de
  /// `error`**, e ler na raiz fazia toda recusa chegar como falha sem nome.
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
