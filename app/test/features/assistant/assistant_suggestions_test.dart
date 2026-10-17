import 'package:cajui/src/features/assistant/application/assistant_suggestions.dart';
import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

void main() {
  group('as sugestões da primeira conversa acompanham o mês', () {
    test('sem planilha, as de sempre', () {
      expect(
        AssistantSuggestions.of(null, testToday.budgetMonth),
        AssistantSuggestions.always,
      );
    });

    test(
      'com conta aberta, o que falta e a conta que vence primeiro',
      () async {
        final container = ProviderContainer(
          overrides: testOverrides(
            journal: MemoryLedgerJournal(samplePlanEvents),
          ),
        );
        addTearDown(container.dispose);
        await container.read(ledgerProvider.future);

        final suggestions = AssistantSuggestions.of(
          container.read(financesProvider),
          testToday.budgetMonth,
        );

        expect(suggestions, hasLength(3));
        expect(suggestions.first, 'O que falta pagar?');
        expect(suggestions[1], 'Paguei Aluguel');
      },
    );
  });
}
