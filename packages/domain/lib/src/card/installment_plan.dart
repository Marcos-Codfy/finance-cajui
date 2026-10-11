import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/card/credit_card.dart';
import 'package:domain/src/card/installment.dart';
import 'package:domain/src/card/statement_cycle.dart';
import 'package:domain/src/money/money.dart';
import 'package:meta/meta.dart';

/// O parcelamento de uma compra no cartão (RN-311).
///
/// A parcela *k* conta no mês em que vence a fatura que a cobra; a primeira
/// vem na fatura do ciclo da compra. O parcelamento entra no orçamento como
/// **compromisso do bloco de dívidas**: não consome o variável do mês em que
/// a compra foi feita (RN-312).
@immutable
final class InstallmentPlan {
  /// O parcelamento de [principal] em [count] vezes, para uma compra feita em
  /// [purchasedOn] no cartão [card].
  ///
  /// Sem juros, o valor é rateado sem perder centavo (RN-102). Com juros,
  /// informa-se o valor de cada parcela em [installmentAmount]: o lançamento
  /// continua valendo o preço à vista, e a diferença aparece à parte, como
  /// custo do parcelamento (RN-314).
  factory forPurchase({
    required CreditCard card,
    required LocalDate purchasedOn,
    required Money principal,
    required int count,
    Money? installmentAmount,
  }) {
    assert(count >= 2, 'Parcelamento tem ao menos duas parcelas.');
    final first = StatementCycle.containing(card, purchasedOn).dueMonth;
    final amounts = installmentAmount == null
        ? principal.split(count)
        : List.filled(count, installmentAmount);
    return InstallmentPlan._(
      cardId: card.id,
      principal: principal,
      installments: List.unmodifiable([
        for (final (index, amount) in amounts.indexed)
          Installment(
            number: index + 1,
            amount: amount,
            dueMonth: first.addMonths(index),
          ),
      ]),
    );
  }

  const new _({
    required this.cardId,
    required this.principal,
    required this.installments,
  });

  /// O cartão em que a compra foi parcelada.
  final String cardId;

  /// O preço à vista: é o valor do lançamento.
  final Money principal;

  /// As parcelas, na ordem.
  final List<Installment> installments;

  /// Em quantas vezes.
  int get count => installments.length;

  /// A soma de todas as parcelas.
  Money get total =>
      installments.fold(Money.zero, (sum, item) => sum + item.amount);

  /// O custo de parcelar: zero quando é sem juros (RN-314).
  Money get interestTotal => total - principal;

  /// A parcela que conta em [month], se houver.
  Installment? installmentDueIn(BudgetMonth month) {
    for (final installment in installments) {
      if (installment.dueMonth == month) return installment;
    }
    return null;
  }

  /// O **total ainda comprometido** a partir de [month], inclusive — o número
  /// que sempre acompanha a parcela na tela (RN-313).
  ///
  /// Geladeira em 10× de R$ 150,00, na 3ª parcela: ainda R$ 1.200,00.
  Money committedFrom(BudgetMonth month) => installments
      .where((installment) => !installment.dueMonth.isBefore(month))
      .fold(Money.zero, (sum, item) => sum + item.amount);
}
