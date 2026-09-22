import 'package:meta/meta.dart';

/// Um convite para cadastrar outro aparelho: o código e quanto ele dura.
@immutable
final class DeviceInvite {
  /// Cria o convite.
  const new({required this.code, required this.seconds});

  /// O código a digitar no outro aparelho.
  final String code;

  /// Por quantos segundos ele vale.
  final int seconds;
}
