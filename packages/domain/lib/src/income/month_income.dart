import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/income/income_receipt.dart';
import 'package:domain/src/income/income_source.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/money/tender_amounts.dart';
import 'package:meta/meta.dart';

/// A renda de um mês, por moeda.
///
/// Para cada fonte ativa vale o **esperado**, até que o recebimento do mês
/// seja registrado; aí vale o **recebido** (RN-131). Entradas avulsas somam
/// só no mês em que ocorreram (RN-133). Dinheiro e vale ficam em totais
/// separados, como tudo no Cajui (RN-111).
@immutable
final class MonthIncome {
  /// Calcula a renda de [month] a partir das fontes e dos recebimentos.
  factory of(
    BudgetMonth month, {
    required Iterable<IncomeSource> sources,
    required Iterable<IncomeReceipt> receipts,
  }) {
    final ofMonth = receipts
        .where((receipt) => month.contains(receipt.receivedOn))
        .toList();
    var total = TenderAmounts.zero;
    for (final source in sources.where((s) => s.isActiveIn(month))) {
      total += TenderAmounts.single(source.tender, _amountOf(source, ofMonth));
    }
    for (final receipt in ofMonth.where((receipt) => receipt.isOneOff)) {
      total += TenderAmounts.single(receipt.tender, receipt.amount);
    }
    return MonthIncome._(month, total);
  }

  const new _(this.month, this.amounts);

  /// O mês a que a renda se refere.
  final BudgetMonth month;

  /// A renda em dinheiro e a renda em vale, separadas.
  final TenderAmounts amounts;

  /// Há renda em dinheiro no mês. Sem ela, todo indicador de proporção é
  /// **indefinido** — nunca zero, nunca infinito (RN-135 e RN-604).
  bool get hasCashIncome => amounts.cash.isPositive;

  /// O recebido de [source] no mês, se já houve recebimento; senão, o
  /// esperado.
  static Money _amountOf(IncomeSource source, List<IncomeReceipt> ofMonth) {
    final received = ofMonth.where((receipt) => receipt.sourceId == source.id);
    if (received.isEmpty) return source.expectedAmount;
    return received.fold(Money.zero, (sum, receipt) => sum + receipt.amount);
  }
}
