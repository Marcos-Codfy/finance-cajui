import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/money/money.dart';
import 'package:meta/meta.dart';

/// O **valor para quitar hoje**, informado pela pessoa a partir do que o
/// credor disse (RN-511).
///
/// O Cajui não calcula tabela de juros por conta própria: fingiria uma
/// precisão que não tem. Mostra o que foi informado, com a data — e avisa
/// quando o número envelheceu.
@immutable
final class PayoffQuote {
  /// Cria a cotação de [amount], informada em [quotedOn].
  const new({required this.amount, required this.quotedOn});

  /// Depois de quantos dias a cotação é mostrada como desatualizada.
  static const staleAfterDays = 30;

  /// O valor para quitar.
  final Money amount;

  /// O dia em que o valor foi informado.
  final LocalDate quotedOn;

  /// Há quantos dias foi informado.
  int ageOn(LocalDate today) => quotedOn.daysUntil(today);

  /// Informado há mais de 30 dias: "pode ter mudado" (RN-512).
  bool isStaleOn(LocalDate today) => ageOn(today) > staleAfterDays;
}
