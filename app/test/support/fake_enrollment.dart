import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/auth/application/device_enrollment.dart';

/// Um cadastro de mentira: aceita qualquer código, e guarda o que recebeu
/// para o teste conferir.
///
/// Nasce como o celular que o servidor já conhece; com `refused`, como o
/// que ele recusou — o aparelho recém-instalado, ou o que foi descadastrado.
final class FakeEnrollment implements DeviceEnrollment {
  /// Cria o dublê.
  new({this._refused = false, this.failure});

  /// O que o cadastro responde. `null` é "deu certo".
  final ErrorCode? failure;

  /// Os códigos que chegaram, na ordem.
  final codes = <String>[];

  bool _refused;

  @override
  bool get isRefused => _refused;

  @override
  Future<ErrorCode?> enroll(String code, {required String name}) async {
    codes.add(code);
    if (failure == null) _refused = false;
    return failure;
  }
}
