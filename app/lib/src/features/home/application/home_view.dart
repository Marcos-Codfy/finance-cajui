import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// O que o Início mostra, já respondido pelo domínio: o mês da planilha, a
/// semana, quanto ainda se deve, os cartões que pedem atenção e a sugestão
/// de contas. A tela só lê; nenhuma conta é feita aqui.
@immutable
final class HomeView {
  /// Cria a visão.
  const new({
    required this.today,
    required this.budget,
    required this.week,
    required this.owed,
    required this.hasPlan,
    required this.entriesThisMonth,
    this.suggestion,
    this.cardsNearLimit = const [],
  });

  /// A visão de [book] em [today].
  factory of(Finances finances, LedgerBook book, LocalDate today) {
    final month = today.budgetMonth;
    return HomeView(
      today: today,
      budget: finances.budgetFor(month),
      week: finances.weekOf(today),
      owed: finances.owedOn(today),
      hasPlan: !finances.plan.isEmpty,
      entriesThisMonth: book.entries
          .where((entry) => entry.occurredOn.budgetMonth == month)
          .length,
      suggestion: finances.suggestion(today),
      cardsNearLimit: [
        for (final card in book.cards)
          if (finances.cardUsage(card, month)?.alert == CardUsageAlert.high)
            card.name,
      ],
    );
  }

  /// O dia de hoje.
  final LocalDate today;

  /// O mês corrente, como na planilha.
  final MonthBudget budget;

  /// A semana corrente.
  final WeekAllowance week;

  /// Quanto ainda se deve, somando dívidas e parcelas de cartão.
  final Money owed;

  /// Se há plano: salários, contas, vale ou dízimo.
  final bool hasPlan;

  /// Quantos lançamentos o mês tem.
  final int entriesThisMonth;

  /// "Minhas contas" sugeridas, quando cabe sugerir (RN-1050).
  final PlanSuggestion? suggestion;

  /// Os cartões que passaram de 80% do limite no mês (RN-1020).
  final List<String> cardsNearLimit;
}

/// A visão do Início; nula enquanto o livro abre.
final homeViewProvider = Provider<HomeView?>((ref) {
  final finances = ref.watch(financesProvider);
  final book = ref.watch(ledgerProvider).value;
  if (finances == null || book == null) return null;
  return HomeView.of(finances, book, ref.watch(clockProvider).today());
});
