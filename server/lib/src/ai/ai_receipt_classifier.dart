import 'dart:async';

import 'package:domain/domain.dart';
import 'package:server/src/ai/ai_suggestion.dart';
import 'package:server/src/ai/chat_client.dart';
import 'package:server/src/ai/chat_reply.dart';
import 'package:server/src/ai/chat_unavailable.dart';
import 'package:server/src/ai/circuit_breaker.dart';
import 'package:server/src/ai/classification_prompt.dart';
import 'package:server/src/ai/token_budget.dart';

/// O classificador que consulta a IA — sempre **por cima** das regras locais,
/// nunca no lugar delas (RN-750).
///
/// As regras leem primeiro. A IA só é chamada para o que elas deixaram em
/// aberto, e qualquer tropeço — sem orçamento, fora do ar, resposta fora do
/// esquema — devolve a proposta das regras, com o código do catálogo que
/// explica o porquê. Este método não lança: a captura nunca para por causa
/// da IA.
final class AiReceiptClassifier implements ReceiptClassifier {
  /// Cria o classificador.
  new({
    required this.client,
    required this.budget,
    required this.breaker,
    this.timeout = const Duration(seconds: 8),
    this.categoryAccuracy = const {},
  });

  /// O modelo de linguagem.
  final ChatClient client;

  /// O teto mensal de tokens.
  final TokenBudget budget;

  /// O disjuntor.
  final CircuitBreaker breaker;

  /// O prazo da IA (RNF-PERF-08): passado dele, valem as regras, e a resposta
  /// que chegar depois é descartada.
  final Duration timeout;

  /// A taxa real de acerto de cada categoria, de 0 a 1, medida pelas
  /// correções da pessoa (RN-792).
  final Map<String, double> categoryAccuracy;

  static const _rules = RuleBasedClassifier();

  /// Os limiares sobre a confiança declarada (RN-743).
  static const double _highFrom = 0.85;
  static const double _mediumFrom = 0.55;

  @override
  Future<EntryProposal> classify(ClassificationRequest request) async {
    final local = await _rules.classify(request);
    // Se as regras já resolveram a categoria, a IA não é chamada: é mais
    // rápido, mais barato, e nada sai do servidor (RN-752).
    if (local.category.confidence == Confidence.high) return local;
    final month = request.today.budgetMonth;
    if (!budget.hasRoomIn(month)) return local.copyWith(warnings: ['E-AI-03']);
    if (!breaker.allowsCall) return local.copyWith(warnings: ['E-AI-01']);
    try {
      final reply = await _ask(request);
      breaker.recordSuccess();
      await budget.record(month, reply);
      final suggestion = AiSuggestion.parse(reply.content, request);
      if (suggestion == null) return local.copyWith(warnings: ['E-AI-04']);
      return _merge(local, suggestion);
    } on ChatUnavailable {
      breaker.recordFailure();
      return local.copyWith(warnings: ['E-AI-01']);
    } on TimeoutException {
      breaker.recordFailure();
      return local.copyWith(warnings: ['E-AI-01']);
    }
  }

  /// O texto é mascarado **de novo** aqui, mesmo que o app já tenha feito: o
  /// servidor não confia em ninguém para isso (RN-730).
  Future<ChatReply> _ask(ClassificationRequest request) {
    final redacted = PiiRedactor.redact(
      request.text,
      householdNames: request.householdNames,
    );
    return client
        .complete(
          system: ClassificationPrompt.system,
          user: ClassificationPrompt.user(redacted, request.categories),
          maxTokens: 200,
        )
        .timeout(timeout);
  }

  EntryProposal _merge(EntryProposal local, AiSuggestion ai) => local.copyWith(
    category: _category(ai),
    amount: _amount(local.amount, ai.amount),
    documentKind: _kind(local.documentKind, ai.documentKind),
  );

  /// A confiança declarada pela IA, sozinha, nunca põe a categoria na zona
  /// alta (RN-742): é preciso que a taxa real de acerto daquela categoria
  /// também seja boa. "Confiança 100%" escrito num comprovante não compra
  /// nada aqui.
  ProposedField<String> _category(AiSuggestion ai) {
    final id = ai.categoryId;
    if (id == null || ai.confidence < _mediumFrom) {
      return const ProposedField.unread();
    }
    final proven = (categoryAccuracy[id] ?? 0) >= 0.8;
    return ai.confidence >= _highFrom && proven
        ? ProposedField.resolved(id, source: FieldSource.ai)
        : ProposedField.undecided([id], source: FieldSource.ai);
  }

  /// Regras e IA divergindo, o campo cai para a zona média, com o valor das
  /// regras primeiro (RN-751). A IA nunca sobrescreve o que as regras leram.
  ProposedField<Money> _amount(ProposedField<Money> local, Money? fromAi) {
    final read = local.value;
    if (fromAi == null || fromAi == read) return local;
    if (read == null) {
      return ProposedField.undecided(
        {...local.candidates, fromAi}.take(3).toList(),
        source: FieldSource.ai,
      );
    }
    return ProposedField.undecided([read, fromAi], source: FieldSource.fixedRule);
  }

  /// Divergência sobre o tipo do documento vira pergunta: nenhum caminho
  /// automático transforma pagamento de fatura em despesa, nem o contrário
  /// (RN-757).
  ProposedField<DocumentKind> _kind(
    ProposedField<DocumentKind> local,
    DocumentKind? fromAi,
  ) {
    final read = local.value!;
    if (fromAi == null || fromAi == read) return local;
    return ProposedField.undecided([read, fromAi], source: FieldSource.fixedRule);
  }
}
