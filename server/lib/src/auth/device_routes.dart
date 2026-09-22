import 'package:api_contract/api_contract.dart';
import 'package:server/src/auth/authenticate.dart';
import 'package:server/src/auth/device_registry.dart';
import 'package:server/src/auth/enrollment_codes.dart';
import 'package:server/src/auth/session_book.dart';
import 'package:server/src/auth/session_scope.dart';
import 'package:server/src/http/error_response.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// Os aparelhos com acesso, vistos de dentro: listar, convidar outro e tirar
/// um de circulação.
///
/// Fica **atrás da autenticação**, ao contrário de `/v1/auth`: quem emite um
/// convite ou revoga um aparelho já provou ser um aparelho cadastrado. É o
/// que permite cadastrar o computador ou um celular novo **sem abrir o
/// servidor por fora** — o código nasce no aparelho que você já tem na mão.
final class DeviceRoutes {
  /// Cria as rotas sobre o cadastro e os códigos.
  new({required this.devices, required this.codes, required this.sessions});

  /// Os aparelhos cadastrados.
  final DeviceRegistry devices;

  /// Os códigos de cadastro.
  final EnrollmentCodes codes;

  /// As sessões abertas, para a revogação valer na hora.
  final SessionBook sessions;

  /// O roteador, montado em `/v1/devices`.
  Router get router => Router()
    ..get('/', _list)
    ..post('/codes', _issue)
    ..delete('/<id>', _revoke);

  Future<Response> _list(Request request) async => Responses.json({
    'devices': [for (final device in devices.devices) device.toJson()],
  });

  /// Emite um convite. Só um aparelho **completo** convida: a web é de
  /// leitura, e quem só lê não decide quem mais entra (T-12).
  Future<Response> _issue(Request request) async {
    if (Authenticate.sessionOf(request).scope == SessionScope.webReadOnly) {
      return Responses.error(request, ErrorCode.auth03, status: 403);
    }
    return Responses.json({
      'code': codes.issue(),
      'expiresInSeconds': EnrollmentCodes.validity.inSeconds,
    });
  }

  /// Tira um aparelho de circulação. A sessão dele morre junto: revogar que
  /// só vale no próximo login não é revogar.
  Future<Response> _revoke(Request request, String id) async {
    if (Authenticate.sessionOf(request).scope == SessionScope.webReadOnly) {
      return Responses.error(request, ErrorCode.auth03, status: 403);
    }
    await devices.revoke(id);
    sessions.closeAllOf(id);
    return Responses.json({'revoked': id});
  }
}
