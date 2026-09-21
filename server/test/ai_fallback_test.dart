import 'package:domain/domain.dart';
import 'package:server/src/ai/ai_receipt_classifier.dart';
import 'package:server/src/ai/chat_unavailable.dart';
import 'package:server/src/ai/circuit_breaker.dart';
import 'package:server/src/ai/token_budget.dart';
import 'package:test/test.dart';

import 'support/receipt_samples.dart';
import 'support/scripted_chat_client.dart';

void main() {
  group('quando a IA não está disponível', () {
    Future<EntryProposal> withClient(
      ScriptedChatClient client, {
      TokenBudget? budget,
      CircuitBreaker? breaker,
    }) async => await AiReceiptClassifier(
      client: client,
      budget: budget ?? await sampleBudget(),
      breaker: breaker ?? CircuitBreaker(),
      timeout: const Duration(milliseconds: 50),
    ).classify(sampleRequest(sampleCoupon));

    test(
      'E-AI-01 fora do ar: valem as regras, e a proposta continua válida',
      () async {
        final proposal = await withClient(
          ScriptedChatClient(failure: const ChatUnavailable()),
        );

        expect(proposal.warnings, ['E-AI-01']);
        expect(proposal.amount.value, const Money.fromCents(8640));
      },
    );

    test(
      'RNF-PERF-08 passou do prazo: a resposta atrasada é descartada',
      () async {
        final proposal = await withClient(
          ScriptedChatClient(delay: const Duration(milliseconds: 300)),
        );

        expect(proposal.warnings, ['E-AI-01']);
      },
    );

    test('E-AI-03 e RN-777 sem orçamento, nenhuma chamada sai', () async {
      final client = ScriptedChatClient();

      final proposal = await withClient(
        client,
        budget: await sampleBudget(limit: 0),
      );

      expect(proposal.warnings, ['E-AI-03']);
      expect(client.calls, isEmpty);
    });

    test('RNF-AI-04 o consumo é gravado e conta contra o teto', () async {
      final budget = await sampleBudget(limit: 500);
      final client = ScriptedChatClient(content: '{"confidence": 0.1}');

      await withClient(client, budget: budget);
      expect(budget.spentIn(const BudgetMonth(2026, 9)), 440);

      // 440 de 500: ainda há orçamento, e a segunda chamada sai.
      final second = await withClient(client, budget: budget);
      expect(second.warnings, isEmpty);
      expect(budget.spentIn(const BudgetMonth(2026, 9)), 880);
      expect((await withClient(client, budget: budget)).warnings, ['E-AI-03']);
    });

    test('T-25 o disjuntor abre depois de falhas seguidas', () async {
      final breaker = CircuitBreaker(failureThreshold: 2);
      final client = ScriptedChatClient(failure: const ChatUnavailable());

      await withClient(client, breaker: breaker);
      await withClient(client, breaker: breaker);
      await withClient(client, breaker: breaker);

      expect(client.calls, hasLength(2));
    });

    test('RN-752 com regra aprendida, a IA nem é chamada', () async {
      final client = ScriptedChatClient();
      final classifier = AiReceiptClassifier(
        client: client,
        budget: await sampleBudget(),
        breaker: CircuitBreaker(),
      );

      final proposal = await classifier.classify(
        ClassificationRequest(
          text: ReceiptText.clean(sampleCoupon),
          categories: const [sampleGroceries],
          today: LocalDate(2026, 9, 20),
          learnedRules: const {'mercado boa compra': 'groceries'},
        ),
      );

      expect(proposal.category.value, 'groceries');
      expect(client.calls, isEmpty);
    });
  });
}
