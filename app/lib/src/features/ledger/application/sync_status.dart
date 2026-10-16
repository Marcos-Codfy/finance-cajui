import 'package:meta/meta.dart';

/// Como está a conversa do aparelho com o servidor, para o selo do Início
/// (17/10/2026): responde de relance "o servidor tem tudo?", a dúvida que
/// a Juju com outra sobra levantou.
@immutable
final class SyncStatus {
  /// O estado; o inicial é "ainda não conversou".
  const new({this.running = false, this.lastOkAt, this.failing = false});

  /// Se uma sincronização está acontecendo agora.
  final bool running;

  /// Quando a última deu certo, subindo e descendo tudo.
  final DateTime? lastOkAt;

  /// Se a última falhou — sem rede, sem servidor. O que foi lançado fica
  /// guardado no aparelho e sobe na próxima.
  final bool failing;
}
