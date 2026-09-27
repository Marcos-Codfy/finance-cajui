import 'package:domain/src/calendar/local_date.dart';

/// De onde o domínio sabe que dia é hoje.
///
/// Nenhuma regra chama `DateTime.now()`: o relógio entra por esta porta. É o
/// que deixa o teste de "data da compra no futuro" dar o mesmo resultado
/// hoje e daqui a um ano, e o que impede aparelho e servidor de discordarem
/// por causa do fuso de cada um.
abstract interface class Clock {
  /// O dia de hoje, no fuso de quem usa o app.
  LocalDate today();

  /// O instante de agora, em UTC. É o que decide quem venceu quando dois
  /// aparelhos mexeram na mesma coisa: o mais novo vale.
  DateTime now();
}
