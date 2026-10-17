import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/home/application/home_view.dart';
import 'package:cajui/src/features/home_widget/application/home_snapshot.dart';
import 'package:cajui/src/features/home_widget/application/widget_bill.dart';
import 'package:cajui/src/features/home_widget/application/widget_bills.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/review/application/review_providers.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O retrato que vai para o widget da tela inicial e para o aviso de
/// domingo; `null` enquanto o livro abre.
///
/// **É o único lugar que diz de onde sai o número do widget.** Ele sai de
/// [homeViewProvider] — o mesmo mês que o Início mostra primeiro —, e as
/// contas a vencer, de [WidgetBills]. O publicador, o canal e o lado nativo
/// só repassam o que ele disser.
final homeSnapshotProvider = Provider<HomeSnapshot?>((ref) {
  final view = ref.watch(homeViewProvider);
  final finances = ref.watch(financesProvider);
  final book = ref.watch(ledgerProvider).value;
  if (view == null || finances == null || book == null) return null;
  final review = ref.watch(reviewItemsProvider);
  return _HomeWords.of(
    view,
    reviewDates: [for (final entry in review) entry.occurredOn],
    bills: WidgetBills.upcoming(
      finances,
      today: view.today,
      cardIds: {for (final card in book.cards) card.id},
    ),
  );
});

/// As frases do widget. O "pode gastar por semana" saiu em 11/10/2026, e o
/// número passou a ser o do mês.
///
/// Sem o valor da falta: o widget fica à vista de quem olha a tela do
/// celular, e esse número mora dentro do app (no espírito da RN-843). Mês que
/// não fecha mostra o que sai do bolso, e a frase manda abrir o app.
abstract final class _HomeWords {
  static HomeSnapshot of(
    HomeView view, {
    required List<LocalDate> reviewDates,
    required List<WidgetBill> bills,
  }) {
    final (label, amount, caption) = _words(view);
    return HomeSnapshot(
      label: label,
      amount: MoneyFormat.brl(amount),
      caption: caption,
      validUntil: view.budget.month.lastDay,
      reviewDates: reviewDates,
      bills: bills,
    );
  }

  static (String, Money, String) _words(HomeView view) {
    final budget = view.budget;
    final month = DateLabels.month(budget.month).split(' ').first;
    return switch (view) {
      // Sem plano, o widget mostra o que já saiu, como o Início (RN-1050).
      HomeView(hasPlan: false) => (
        'Já saiu este mês',
        budget.outOfPocket,
        'Com Minhas contas, aqui aparece a sobra do mês.',
      ),
      HomeView(budget: MonthBudget(closes: true)) => (
        'Sobra de $month',
        budget.result,
        'Depois de pagar tudo, pelo que está lançado.',
      ),
      _ => (
        'Sai do bolso em $month',
        budget.outOfPocket,
        'O mês ainda não fecha. Abra o Cajui para ver o que fazer.',
      ),
    };
  }
}
