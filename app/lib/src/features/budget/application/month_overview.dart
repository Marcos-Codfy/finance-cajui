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
    final plan = book.setup.planFor(
      month,
      // O vale que o mês tem para gastar: o que resta mais o que já saiu.
      voucherAvailable: book.voucher.balance + spent.mealVoucher,
    );
    final spending = MonthSpending.of(
      month,
      entries: book.entries,
      categories: book.categoriesById,
    );
    return MonthOverview._(
      today: today,
      plan: plan,
      voucher: book.voucher,
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
    required this.voucher,
    required this.indicators,
    required this.week,
  });

  /// O dia de hoje.
  final LocalDate today;

  /// O plano do mês.
  final MonthPlan plan;

  /// A conta do vale.
  final VoucherAccount voucher;

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
