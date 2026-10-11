import 'package:domain/src/debts/debt.dart';

/// A ordem de quitação das dívidas, como a pessoa decidiu: "primeiro o
/// Santander, depois o carnê. Uma de cada vez".
///
/// A ordem é uma lista de identificadores, e não um número em cada dívida:
/// dois celulares reordenando ao mesmo tempo nunca produzem um empate — vale
/// a lista mais nova inteira.
abstract final class DebtOrder {
  /// [debts] na ordem [order]. As que a lista não cita vêm depois, na ordem
  /// em que chegaram; ids da lista sem dívida são ignorados.
  static List<Debt> apply(Iterable<Debt> debts, List<String> order) {
    final byId = {for (final debt in debts) debt.id: debt};
    final ordered = [for (final id in order) ?byId.remove(id)];
    return [...ordered, ...byId.values];
  }
}
