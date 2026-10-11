import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/auth/application/code_exchange.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';

/// A troca pelo servidor: `POST /v1/auth/code` (ADR-027).
final class HttpCodeExchange implements CodeExchange {
  /// Cria a troca sobre [_api].
  const new(this._api);

  final CajuiApi _api;

  @override
  Future<CodeOutcome> tokenFor(String code) async {
    final (:body, :failure) = await _api.post('v1/auth/code', {'code': code});
    final token = body?['token'];
    if (failure == null && token is String && token.isNotEmpty) {
      return (token: token, error: null, retryAfterSeconds: null);
    }
    // O servidor responde `E-AUTH-03` a código errado, a entrada em espera e
    // a servidor sem segredo, de propósito igual (T-12). Para quem digitou,
    // é o "esse código não serviu".
    final error = failure?.code;
    return (
      token: null,
      error: error == null || error == ErrorCode.auth03
          ? ErrorCode.auth04
          : error,
      retryAfterSeconds: failure?.retryAfterSeconds,
    );
  }
}
