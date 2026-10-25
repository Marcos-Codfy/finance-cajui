import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/assistant/application/assistant_action_done.dart';
import 'package:cajui/src/features/assistant/application/assistant_reply.dart';
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

  group('as sugestões depois de uma resposta acompanham a conversa', () {
    const answered = AssistantAnswered('Neste mês sobram o previsto.');

    List<String> after(List<(String, AssistantReply)> exchanges) =>
        AssistantSuggestions.after(exchanges, null, testToday.budgetMonth);

    test('depois da sobra, para onde foi; nunca a mesma pergunta de novo', () {
      final suggestions = after([('Quanto sobra neste mês?', answered)]);

      expect(suggestions.first, 'Para onde foi o dinheiro deste mês?');
      expect(suggestions, isNot(contains('Quanto sobra neste mês?')));
      expect(suggestions, hasLength(lessThanOrEqualTo(3)));
    });

    test('depois de ver para onde foi, volta à sobra', () {
      final suggestions = after([
        ('Para onde foi o dinheiro deste mês?', answered),
      ]);

      expect(suggestions.first, 'Quanto sobra neste mês?');
    });

    test('depois de um lançamento feito pela Juju, a sobra e o que falta', () {
      final suggestions = after([
        (
          'Gastei 35 no mercado',
          const AssistantAnswered(
            'Lancei.',
            actions: [
              AssistantActionDone(
                kind: 'recorded',
                id: 'e1',
                label: 'Mercado',
                amountCents: 3500,
              ),
            ],
          ),
        ),
      ]);

      expect(suggestions.first, 'Quanto sobra neste mês?');
      expect(suggestions, isNot(contains('Gastei 35 no mercado')));
    });

    test('o que já foi perguntado na conversa não volta', () {
      final suggestions = after([
        ('Para onde foi o dinheiro deste mês?', answered),
        ('Quanto sobra neste mês?', answered),
      ]);

      expect(suggestions, isNot(contains('Quanto sobra neste mês?')));
      expect(
        suggestions,
        isNot(contains('Para onde foi o dinheiro deste mês?')),
      );
    });

    test('sem resposta de verdade, nada a sugerir', () {
      expect(after(const []), isEmpty);
      expect(after([('oi', const AssistantFailed(ErrorCode.ai01))]), isEmpty);
      expect(
        after([('oi', const AssistantAnswered('x', isFallback: true))]),
        isEmpty,
      );
    });
  });
}
