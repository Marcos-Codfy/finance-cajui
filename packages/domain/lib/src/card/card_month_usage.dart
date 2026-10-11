import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/card/card_usage_alert.dart';
import 'package:domain/src/card/credit_card.dart';
import 'package:domain/src/indicators/percent.dart';
import 'package:domain/src/ledger/entry.dart';
import 'package:domain/src/ledger/reversal.dart';
import 'package:domain/src/money/money.dart';
import 'package:meta/meta.dart';

/// Quanto do limite de um cartão foi usado no mês, como na planilha: a soma
/// dos lançamentos do mês pagos com o cartão, menos os estornos.
///
/// Não é a fatura nem o "tomado" do banco, que conta faturas em aberto e
/// parcelas futuras (RN-305): é a pergunta simples de "quanto já passei
/// neste cartão este mês". A compra parcelada conta inteira no mês da compra,
/// porque é assim que ela toma o limite.
@immutable
final class CardMonthUsage {
  /// Cria o uso.
  const new({required this.limit, required this.used});

  /// O uso de [card] em [month]; `null` quando o cartão não tem limite
  /// informado (RN-302).
  static CardMonthUsage? of(
    CreditCard card,
    BudgetMonth month, {
    required Iterable<Entry> entries,
    Iterable<Reversal> reversals = const [],
  }) {
    final limit = card.creditLimit;
    if (limit == null) return null;
    var used = Money.zero;
    for (final entry in entries) {
      if (entry.occurredOn.budgetMonth != month) continue;
      for (final line in entry.paymentLines) {
        if (line.paymentMethodId == card.id) used += line.amount;
      }
    }
    for (final reversal in reversals) {
      final onCard = reversal.line.paymentMethodId == card.id;
      if (onCard && reversal.occurredOn.budgetMonth == month) {
        used -= reversal.line.amount;
      }
    }
    return CardMonthUsage(limit: limit, used: used.orZeroIfNegative);
  }

  /// O limite do cartão.
  final Money limit;

  /// O usado no mês.
  final Money used;

  /// O que sobra de limite; negativo quando passou.
  Money get left => limit - used;

  /// O usado, em percentual inteiro do limite.
  int? get percent => Percent.of(used, limit);

  /// O aviso. A comparação é em centavos, e não pelo percentual arredondado:
  /// 49,6% não pode acender o aviso de metade.
  CardUsageAlert get alert {
    final usedTimes100 = used.cents * 100;
    if (usedTimes100 >= limit.cents * 80) return CardUsageAlert.high;
    if (usedTimes100 >= limit.cents * 50) return CardUsageAlert.half;
    return CardUsageAlert.none;
  }
}
