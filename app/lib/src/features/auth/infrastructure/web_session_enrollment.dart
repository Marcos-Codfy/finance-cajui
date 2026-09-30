import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/auth/application/device_enrollment.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';

/// Como o navegador entra: com o código que o celular mostrou (ADR-013).
///
/// Cumpre a mesma porta do cadastro do celular de propósito — a tela que
/// pede o código é a mesma, e o que muda é só o que acontece por baixo. Aqui
/// **não nasce aparelho nenhum**: nasce uma sessão de leitura, que vive na
/// memória da aba e morre com ela. Nada fica guardado no navegador, onde
/// qualquer extensão alcançaria.
final class WebSessionEnrollment implements DeviceEnrollment {
  /// Cria o pareamento sobre o cliente [_api].
  const new(this._api);

  final CajuiApi _api;

  @override
  Future<ErrorCode?> enroll(String code, {required String name}) =>
      _api.openWithCode(code);

  /// O navegador não tem chave para o servidor recusar.
  @override
  bool get isRefused => false;
}
