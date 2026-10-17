import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// Uma conta a vencer como o widget grande a mostra: o nome e o dia, já
/// escritos.
///
/// Leva também o dia em ISO, e não só o texto: com o app fechado por dias,
/// o lado nativo tira da lista a conta cujo dia já passou, em vez de dizer
/// "vence dia 10" no dia 12.
@immutable
final class WidgetBill {
  /// Cria a conta.
  const new({required this.name, required this.dueOn, required this.day});

  /// Como a pessoa chama a conta: "Aluguel".
  final String name;

  /// O dia do vencimento.
  final LocalDate dueOn;

  /// O dia já escrito: "vence dia 10", ou "vence 3 de nov." quando é do mês
  /// seguinte.
  final String day;

  @override
  bool operator ==(Object other) =>
      other is WidgetBill &&
      other.name == name &&
      other.dueOn == dueOn &&
      other.day == day;

  @override
  int get hashCode => Object.hash(name, dueOn, day);

  /// O que atravessa o canal.
  Map<String, Object?> toMap() => {'name': name, 'dueOn': '$dueOn', 'day': day};
}
