import 'package:domain/domain.dart';
import 'package:server/src/ai/ai_suggestion.dart';

/// Junta, campo a campo, o que as regras leram do texto e o que a IA leu
/// (ADR-022). É aqui que mora a estratégia de quem acerta o quê:
///
/// - **Valor**: o número ao lado de "TOTAL" ou "VALOR A PAGAR" é lido com
///   exatidão pelas regras, e manda. A IA desempata quando as regras ficaram
///   entre vários números, e lê sozinha quando o texto não trouxe nenhum. Se
///   regra e IA divergem, a tela mostra os dois, o da regra primeiro.
/// - **Data e forma de pagamento**: a do texto, quando as regras acharam; a
///   da IA, quando não.
/// - **Categoria**: o que a pessoa já ensinou vale mais que tudo (RN-765);
///   depois o palpite da IA, com os das regras ao lado.
/// - **Tipo do documento**: "compra" é o que as regras dizem quando nenhuma
///   palavra apareceu, e aí vale a IA; quando as regras acharam uma palavra
///   — "pagamento de fatura" —, divergir vira pergunta, e nenhum caminho
///   automático faz uma despesa sumir (RN-757).
/// - **Descrição**: a da IA, que lê o nome do lugar como gente.
abstract final class ProposalMerge {
  /// Os limiares sobre a confiança declarada na categoria (RN-743).
  static const double highFrom = 0.85;

  /// A proposta de [local] com o que [ai] acrescentou. [sawImage] diz se a
  /// IA viu a foto — aí, entre números em dúvida, o dela vem primeiro.
  static EntryProposal of(
    EntryProposal local,
    AiSuggestion ai, {
    required bool sawImage,
    Map<String, double> categoryAccuracy = const {},
  }) => local.copyWith(
    documentKind: _kind(local.documentKind, ai.documentKind),
    amount: _amount(local.amount, ai, sawImage: sawImage),
    occurredOn: _filled(local.occurredOn, ai.occurredOn),
    paymentKind: _filled(local.paymentKind, ai.paymentKind),
    category: _category(local.category, ai, categoryAccuracy),
    description: ai.description,
    merchant: local.merchant ?? ai.description,
    installments: local.installments ?? ai.installments,
  );

  static ProposedField<DocumentKind> _kind(
    ProposedField<DocumentKind> local,
    DocumentKind? fromAi,
  ) {
    final read = local.value;
    if (fromAi == null || read == null || fromAi == read) return local;
    // Pagamento de fatura só pela IA pergunta (RN-757): dar como certo faria
    // uma despesa sumir — e a foto, que agora vai junto, pode trazer o texto
    // de quem quer isso (INJ-07).
    if (read == DocumentKind.purchase &&
        fromAi != DocumentKind.statementPayment) {
      return ProposedField.resolved(fromAi, source: FieldSource.ai);
    }
    return ProposedField.undecided([
      read,
      fromAi,
    ], source: FieldSource.fixedRule);
  }

  static ProposedField<Money> _amount(
    ProposedField<Money> local,
    AiSuggestion ai, {
    required bool sawImage,
  }) {
    final fromAi = ai.amount;
    if (fromAi == null) return local;
    final read = local.value;
    if (read != null) {
      // O rótulo do texto ("TOTAL") só divide o lugar com outro número do
      // texto. O que a IA leu só da imagem pode ser a foto lida torta.
      if (read == fromAi || !ai.amountInText) return local;
      return ProposedField.undecided([
        read,
        fromAi,
      ], source: FieldSource.fixedRule);
    }
    final candidates = local.candidates;
    if (candidates.isEmpty || candidates.contains(fromAi)) {
      return ProposedField.resolved(fromAi, source: FieldSource.ai);
    }
    final ordered = sawImage
        ? [fromAi, ...candidates]
        : [...candidates, fromAi];
    return ProposedField.undecided(
      ordered.take(3).toList(),
      source: FieldSource.ai,
    );
  }

  /// O campo das regras, quando elas leram; senão, o da IA.
  static ProposedField<T> _filled<T>(ProposedField<T> local, T? fromAi) {
    if (local.value != null || fromAi == null) return local;
    return ProposedField.resolved(fromAi, source: FieldSource.ai);
  }

  /// A confiança declarada pela IA, sozinha, nunca põe a categoria na zona
  /// alta (RN-742): é preciso que a taxa real de acerto daquela categoria
  /// também seja boa. Fora dela, o palpite vem primeiro na lista — e a tela
  /// já o deixa escolhido —, com os das regras ao lado.
  static ProposedField<String> _category(
    ProposedField<String> local,
    AiSuggestion ai,
    Map<String, double> accuracy,
  ) {
    if (local.confidence == Confidence.high) return local;
    final id = ai.categoryId;
    if (id == null) return local;
    final proven = (accuracy[id] ?? 0) >= 0.8;
    if (ai.confidence >= highFrom && proven) {
      return ProposedField.resolved(id, source: FieldSource.ai);
    }
    return ProposedField.undecided(
      [id, ...local.candidates.where((other) => other != id)].take(3).toList(),
      source: FieldSource.ai,
    );
  }
}
