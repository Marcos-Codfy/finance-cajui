import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/auth/application/device_directory.dart';
import 'package:cajui/src/features/auth/application/device_invite.dart';
import 'package:cajui/src/features/auth/application/known_device.dart';

/// A lista de aparelhos de mentira: dois cadastrados, e convites que saem na
/// hora, com o prazo de cada um — dez minutos para outro celular, dois para
/// o navegador.
final class FakeDirectory implements DeviceDirectory {
  /// Cria o dublê.
  new();

  /// Os identificadores tirados, na ordem.
  final revoked = <String>[];

  @override
  Future<(List<KnownDevice>, ErrorCode?)> devices() async => (
    const [
      KnownDevice(id: 'a', name: 'Celular principal', isWeb: false),
      KnownDevice(id: 'b', name: 'S22', isWeb: false),
    ],
    null,
  );

  @override
  Future<(DeviceInvite?, ErrorCode?)> invite() async =>
      (const DeviceInvite(code: 'ABCD1234EF', seconds: 600), null);

  @override
  Future<(DeviceInvite?, ErrorCode?)> webInvite() async =>
      (const DeviceInvite(code: 'WXYZ5678', seconds: 120), null);

  @override
  Future<ErrorCode?> revoke(String id) async {
    revoked.add(id);
    return null;
  }
}
