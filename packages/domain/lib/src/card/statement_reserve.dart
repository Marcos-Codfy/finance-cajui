import 'package:domain/src/card/card_statement.dart';
import 'package:domain/src/card/credit_card.dart';
import 'package:domain/src/card/settlement.dart';
import 'package:domain/src/card/statement_cycle.dart';
import 'package:domain/src/ledger/entry.dart';
import 'package:domain/src/ledger/reversal.dart';
import 'package:domain/src/money/money.dart';

/// A **reserva da fatura**: quanto do dinheiro do mês já tem destino, porque
/// foi gasto à vista no cartão e ainda não saiu da conta (RN-320).
///
/// Não é despesa nova e não reduz a sobra: o valor já contou quando a compra
/// entrou (RN-321). Sobra de R$ 558,00 e reserva de R$ 640,00 são números
/// independentes — a reserva só responde "quanto disso eu não posso tocar".
abstract final class StatementReserve {
  /// A reserva do cartão [card]: as compras à vista, menos os estornos, dos
  /// ciclos que ainda não tiveram liquidação.
  ///
  /// Liquidar a fatura tira o ciclo da reserva (RN-341) — inclusive quando o
  /// pagamento é parcial, porque aí o que sobrou vira dívida (RN-342).
  static Money of(
    CreditCard card, {
    required Iterable<Entry> entries,
    Iterable<Reversal> reversals = const [],
    Iterable<Settlement> settlements = const [],
  }) {
    final settled = {
      for (final settlement in settlements)
        if (settlement.cardId == card.id) settlement.dueMonth,
    };
    final openCycles = {
      for (final entry in entries)
        if (_paidOnCard(card, entry))
          StatementCycle.containing(card, entry.occurredOn),
    }.where((cycle) => !settled.contains(cycle.dueMonth));
    return openCycles.fold(Money.zero, (sum, cycle) {
      final statement = CardStatement.of(
        cycle,
        entries: entries,
        reversals: reversals,
      );
      return sum + statement.purchases - statement.reversed;
    });
  }

  static bool _paidOnCard(CreditCard card, Entry entry) =>
      entry.paymentLines.any(
        (line) => line.kind.isCreditCard && line.paymentMethodId == card.id,
      );
}
