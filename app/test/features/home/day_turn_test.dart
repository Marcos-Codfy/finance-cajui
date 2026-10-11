import 'package:cajui/src/features/home/application/home_view.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/today_controller.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_ledger_journal.dart';
import '../../support/test_scope.dart';

/// Um relógio que a gente adianta, como o tempo passando com o app vivo.
final class _MovingClock implements Clock {
  LocalDate day = LocalDate(2026, 9, 20);

  @override
  LocalDate today() => day;

  @override
  DateTime now() => DateTime.utc(day.year, day.month, day.day, 12);
}

void main() {
  test('o dia vira com o app aberto: o Início passa para o mês novo sem o '
      'livro mudar', () async {
    final clock = _MovingClock();
    final container = ProviderContainer(
      overrides: testOverrides(journal: MemoryLedgerJournal(), clock: clock),
    );
    addTearDown(container.dispose);
    await container.read(ledgerProvider.future);
    expect(container.read(homeViewProvider)!.today, LocalDate(2026, 9, 20));

    clock.day = LocalDate(2026, 10, 1);
    container.read(todayProvider.notifier).check();

    expect(container.read(homeViewProvider)!.today, LocalDate(2026, 10, 1));
    expect(
      container.read(homeViewProvider)!.budget.month,
      const BudgetMonth(2026, 10),
    );
  });
}
