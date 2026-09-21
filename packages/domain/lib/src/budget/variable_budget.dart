import 'package:domain/src/budget/amount_range.dart';
import 'package:domain/src/calendar/month_span.dart';
import 'package:meta/meta.dart';

/// Um gasto variável: uma categoria com faixa (RN-420).
///
/// A ordem em que os variáveis aparecem no plano importa: é nela que o vale
/// alimentação é distribuído entre as categorias elegíveis (RN-426).
@immutable
final class VariableBudget {
  /// Cria o variável da categoria [categoryId].
  const new({
    required this.categoryId,
    required this.range,
    required this.voucherEligible,
    this.validity = MonthSpan.always,
  });

  /// A categoria planejada.
  final String categoryId;

  /// A faixa do mês; o plano usa o máximo (RN-421).
  final AmountRange range;

  /// O vale alimentação pode pagar esta categoria. Vem da categoria; fica
  /// aqui para o plano não precisar consultá-la.
  final bool voucherEligible;

  /// Em que meses a faixa vale (RN-427).
  final MonthSpan validity;
}
