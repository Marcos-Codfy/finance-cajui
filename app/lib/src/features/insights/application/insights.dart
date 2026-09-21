import 'package:cajui/src/features/budget/application/month_overview.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// Os três resumos — do dia, da semana e do mês — montados no aparelho, sem
/// rede e sem IA (RN-851).
///
/// Os números e as frases são do domínio (RN-801, RN-802): o mesmo resumo
/// sai igual aqui e no servidor. E como todo resumo é uma **visão** (RN-807),
/// ele se refaz a cada lançamento: não existe resumo "já enviado" que valha
/// mais que o da tela.
@immutable
final class Insights {
  /// Monta os resumos a partir de [overview] e do livro [book].
  factory of(
    MonthOverview overview,
    LedgerBook book, {
    int pendingCaptures = 0,
  }) {
    final month = overview.plan.month;
    final hasRanges = overview.plan.variables.isNotEmpty;
    return Insights._(
      daily: DailySummary.of(
        overview.today,
        entries: book.entries,
        week: hasRanges ? overview.week : null,
        pendingCaptures: pendingCaptures,
      ),
      weekly: hasRanges
          ? WeeklySummary.of(
              today: overview.today,
              plan: overview.plan,
              spending: overview.indicators.spending,
              week: overview.week,
            )
          : null,
      monthly: MonthlySummary(
        indicators: overview.indicators,
        spent: book.spentIn(month),
        voucherBalance: overview.voucher.balance,
        categoryName: (id) => book.categoryOf(id).name,
      ),
    );
  }

  const new _({
    required this.daily,
    required this.weekly,
    required this.monthly,
  });

  /// O resumo de hoje.
  final DailySummary daily;

  /// O resumo da semana; `null` enquanto o plano não tem faixas de
  /// variáveis — sem elas não existe limite de semana para resumir.
  final WeeklySummary? weekly;

  /// O resumo do mês.
  final MonthlySummary monthly;
}

/// Os resumos em vigor; `null` enquanto o livro abre.
final insightsProvider = Provider<Insights?>((ref) {
  final overview = ref.watch(monthOverviewProvider);
  final book = ref.watch(ledgerProvider).value;
  if (overview == null || book == null) return null;
  return Insights.of(
    overview,
    book,
    pendingCaptures: ref.watch(pendingCapturesProvider).value?.length ?? 0,
  );
});
