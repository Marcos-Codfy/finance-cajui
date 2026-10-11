import 'package:cajui/src/features/auth/application/code_exchange.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';

/// A troca pelo servidor: `POST /v1/auth/code` (ADR-027).
final class HttpCodeExchange implements CodeExchange {
  /// Cria a troca sobre [_api].
  const new(this._api);

  final CajuiApi _api;

  @override
  Future<String?> tokenFor(String code) async {
    final (:body, :failure) = await _api.post('v1/auth/code', {'code': code});
    if (failure != null) return null;
    final token = body?['token'];
    return token is String && token.isNotEmpty ? token : null;
  }
}
