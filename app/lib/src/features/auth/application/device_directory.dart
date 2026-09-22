import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/auth/application/device_invite.dart';
import 'package:cajui/src/features/auth/application/known_device.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Quem tem acesso a esta casa, visto de dentro do app.
///
/// É a porta que permite cadastrar o computador ou um celular novo **sem
/// abrir o servidor por fora**: o convite nasce no aparelho que já está na
/// sua mão, e vale por dez minutos.
abstract interface class DeviceDirectory {
  /// Os aparelhos com acesso agora.
  Future<(List<KnownDevice>, ErrorCode?)> devices();

  /// Emite um convite para cadastrar outro aparelho.
  Future<(DeviceInvite?, ErrorCode?)> invite();

  /// Emite o código que abre a **consulta no navegador** (ADR-013). Vale dois
  /// minutos, e não dez: é o tempo de atravessar a sala com o celular na mão.
  Future<(DeviceInvite?, ErrorCode?)> webInvite();

  /// Tira [id] de circulação. A sessão dele morre junto.
  Future<ErrorCode?> revoke(String id);
}

/// Quem lista e convida aparelhos. A raiz do app decide.
final deviceDirectoryProvider = Provider<DeviceDirectory>(
  (ref) => throw StateError('deviceDirectoryProvider sem override na raiz.'),
);
