import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/money/money.dart';
import 'package:meta/meta.dart';

/// Uma linha do "Mês a mês": quanto entrou, quanto saiu, sobrou ou faltou e
/// quanto ainda se deve no fim do mês.
///
/// Ninguém fecha o mês: a linha é calculada a qualquer hora, dos mesmos
/// fatos, e um lançamento atrasado de setembro muda setembro sozinho, sem
/// botão e sem revisão.
@immutable
final class MonthRecord {
  /// Cria a linha.
  const new({
    required this.month,
    required this.cameIn,
    required this.wentOut,
    required this.stillOwed,
  });

  /// O mês.
  final BudgetMonth month;

  /// O que entrou em dinheiro.
  final Money cameIn;

  /// O que saiu do bolso: o total menos o que o vale cobriu.
  final Money wentOut;

  /// Quanto ainda se devia no fim do mês.
  final Money stillOwed;

  /// Sobrou (positivo) ou faltou (negativo).
  Money get leftOver => cameIn - wentOut;
}
