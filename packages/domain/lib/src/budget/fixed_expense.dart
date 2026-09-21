import 'package:domain/src/calendar/month_span.dart';
import 'package:domain/src/money/money.dart';
import 'package:meta/meta.dart';

/// Um custo fixo: repete-se todo mês com valor conhecido (RN-410).
///
/// Conta cujo valor muda todo mês **não é fixo**, por mais regular que seja:
/// a luz é um variável de faixa estreita (RN-413). Fixo é o que dá para
/// escrever no plano sem olhar a fatura.
@immutable
final class FixedExpense {
  /// Cria o fixo.
  const new({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDay,
    required this.categoryId,
    required this.paymentMethodId,
    this.validity = MonthSpan.always,
  });

  /// O identificador do fixo.
  final String id;

  /// O nome na tela: "Aluguel".
  final String name;

  /// O valor esperado por mês.
  final Money amount;

  /// O dia do vencimento. Em mês mais curto, vale o último dia.
  final int dueDay;

  /// A categoria dos lançamentos que pagam este fixo.
  final String categoryId;

  /// Por onde ele costuma ser pago.
  final String paymentMethodId;

  /// Em que meses o fixo vale (RN-412 e RN-415).
  final MonthSpan validity;
}
