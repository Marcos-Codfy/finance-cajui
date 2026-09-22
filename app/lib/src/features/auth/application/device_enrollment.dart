import 'package:api_contract/api_contract.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cadastrar este aparelho no servidor com o código de dez minutos (ADR-008).
///
/// É uma porta para a tela não conhecer o cliente HTTP: quem cadastra pode
/// ser a API de verdade ou, no teste, um dublê que responde sem rede.
abstract interface class DeviceEnrollment {
  /// Cadastra com [code]. `null` quando deu certo; senão, o código do
  /// catálogo — `E-AUTH-04` para código errado, usado ou vencido.
  Future<ErrorCode?> enroll(String code, {required String name});
}

/// Quem cadastra o aparelho. A raiz do app decide.
final deviceEnrollmentProvider = Provider<DeviceEnrollment>(
  (ref) => throw StateError('deviceEnrollmentProvider sem override na raiz.'),
);
