import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// O mês de relance: o plano, o que já foi gasto e o que isso quer dizer.
///
/// Aqui não há conta nenhuma. Toda regra — pior caso dos variáveis, limite
/// da semana, renda comprometida — é do domínio; esta classe só junta o livro
/// do aparelho com o dia de hoje e pergunta.
@immutable
final class MonthOverview {
  /// Monta a visão do mês de [today] a partir de [book].
  factory of(LedgerBook book, LocalDate today) {
    final month = today.budgetMonth;
    final spent = book.spentIn(month);
    final plan = _planOf(book, month, spent);
    final spending = MonthSpending.of(
      month,
      entries: book.entries,
      reversals: book.reversals,
      categories: book.categoriesById,
    );
    return MonthOverview._(
      today: today,
      plan: plan,
      spent: spent,
      voucher: book.voucher,
      statementReserve: _reserveOf(book),
      hasCards: book.cards.isNotEmpty,
      indicators: MonthIndicators(plan, spending),
      week: WeeklyLimit.of(
        week: BudgetWeek.containing(today),
        variableBudget: plan.variableCash,
        spending: spending,
      ),
    );
  }

  const new _({
    required this.today,
    required this.plan,
    required this.spent,
    required this.voucher,
    required this.statementReserve,
    required this.hasCards,
    required this.indicators,
    required this.week,
  });

  /// O plano do mês, com o vale que ele tem para gastar: o que resta mais o
  /// que já saiu.
  static MonthPlan _planOf(
    LedgerBook book,
    BudgetMonth month,
    TenderAmounts spent,
  ) => book.setup.planFor(
    month,
    voucherAvailable: book.voucher.balance + spent.mealVoucher,
    installmentsDue: book.installmentsDueIn(month),
    receivedCashIncome: book.cashIncomeIn(month),
  );

  /// A reserva de todos os cartões, somada. A conta é do domínio, cartão a
  /// cartão; aqui só se junta.
  static Money _reserveOf(LedgerBook book) => book.cards.fold(
    Money.zero,
    (sum, card) =>
        sum +
        StatementReserve.of(
          card,
          entries: book.entries,
          reversals: book.reversals,
          settlements: book.settlements,
        ),
  );

  /// O dia de hoje.
  final LocalDate today;

  /// O plano do mês.
  final MonthPlan plan;

  /// O que já saiu no mês, nas duas moedas.
  final TenderAmounts spent;

  /// O **custo de vida por dia realizado** (RN-651): o que já saiu
  /// dividido pelos dias decorridos, contando hoje. Ao lado do planejado,
  /// é o que diz se o mês está indo como devia.
  TenderAmounts get realizedDailyCost =>
      indicators.realizedDailyCost(spent, today: today);

  /// A conta do vale.
  final VoucherAccount voucher;

  /// A **reserva da fatura**: o que já foi comprado à vista no cartão e ainda
  /// vai sair da conta quando a fatura vencer. A compra já contou no mês em
  /// que foi feita (RN-310); a reserva só lembra que o dinheiro tem dono.
  final Money statementReserve;

  /// Se há cartão cadastrado — sem cartão, a reserva nem aparece.
  final bool hasCards;

  /// A sobra prevista, a renda comprometida e os ajustes possíveis.
  final MonthIndicators indicators;

  /// O limite da semana em curso (RN-640 a RN-645).
  final WeeklyLimit week;

  /// Se há renda em dinheiro cadastrada. Sem ela, proporção nenhuma existe
  /// — nunca 0%, nunca infinito (RN-604).
  bool get hasIncome => plan.cashIncome.isPositive;
}

/// A visão do mês em vigor; `null` enquanto o livro abre.
final monthOverviewProvider = Provider<MonthOverview?>((ref) {
  final book = ref.watch(ledgerProvider).value;
  if (book == null) return null;
  return MonthOverview.of(book, ref.watch(clockProvider).today());
});
