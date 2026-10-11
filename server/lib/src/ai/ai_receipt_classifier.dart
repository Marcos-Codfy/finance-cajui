import 'dart:async';

import 'package:domain/domain.dart';
import 'package:server/src/ai/ai_suggestion.dart';
import 'package:server/src/ai/chat_client.dart';
import 'package:server/src/ai/chat_message.dart';
import 'package:server/src/ai/chat_reply.dart';
import 'package:server/src/ai/chat_unavailable.dart';
import 'package:server/src/ai/circuit_breaker.dart';
import 'package:server/src/ai/classification_prompt.dart';
import 'package:server/src/ai/proposal_merge.dart';
import 'package:server/src/ai/receipt_image.dart';
import 'package:server/src/ai/suggestion_cache.dart';
import 'package:server/src/ai/token_budget.dart';

/// O classificador que consulta a IA — sempre **junto** das regras locais,
/// nunca no lugar delas (RN-750, ADR-022).
///
/// As regras leem primeiro. Com a foto, a IA é chamada sempre: ela vê o que
/// o leitor do celular não viu. Só com texto, ela fica de fora quando a
/// regra que a própria pessoa ensinou já resolveu a categoria. Qualquer
/// tropeço — sem orçamento, fora do ar, resposta fora do esquema — devolve
/// a proposta das regras, com o código do catálogo que explica o porquê.
/// Este método não lança: a captura nunca para por causa da IA.
final class AiReceiptClassifier implements ReceiptClassifier {
  /// Cria o classificador.
  new({
    required this.client,
    required this.budget,
    required this.breaker,
    this.timeout = const Duration(seconds: 8),
    this.imageTimeout = const Duration(seconds: 35),
    this.categoryAccuracy = const {},
    SuggestionCache? cache,
  }) : cache = cache ?? SuggestionCache();

  /// O modelo de linguagem.
  final ChatClient client;

  /// O teto mensal de tokens.
  final TokenBudget budget;

  /// O disjuntor.
  final CircuitBreaker breaker;

  /// O prazo da IA só com texto (RNF-PERF-08): passado dele, valem as
  /// regras, e a resposta que chegar depois é descartada.
  final Duration timeout;

  /// O prazo da IA com a foto: ler imagem leva mais que ler texto.
  final Duration imageTimeout;

  /// A taxa real de acerto de cada categoria, de 0 a 1, medida pelas
  /// correções da pessoa (RN-792).
  final Map<String, double> categoryAccuracy;

  /// As respostas já pagas, para o mesmo comprovante não custar de novo
  /// (RN-778).
  final SuggestionCache cache;

  static const _rules = RuleBasedClassifier();

  /// O teto da resposta só com texto. O objeto de um comprovante tem uns
  /// cem tokens, mas o texto também pode ser de um extrato, e resposta
  /// cortada no meio não se lê: perde tudo, até o tipo. O teto não custa
  /// nada — paga-se o que a IA escreve.
  static const _maxTokens = 2000;

  /// O teto com a foto: trinta linhas de extrato chegam perto de 2.000
  /// tokens, e o modelo às vezes passa das trinta.
  static const _maxTokensWithImages = 4000;

  @override
  Future<EntryProposal> classify(ClassificationRequest request) async {
    final local = await _rules.classify(request);
    // Só com texto, e com a categoria resolvida pelo que a pessoa ensinou, a
    // IA não acrescentaria nada que valha a espera (RN-752).
    if (!request.hasImages && local.category.confidence == Confidence.high) {
      return local;
    }
    // O texto é mascarado **de novo** aqui, mesmo que o app já tenha feito:
    // o servidor não confia em ninguém para isso (RN-730).
    final redacted = PiiRedactor.redact(
      request.text,
      householdNames: request.householdNames,
    );
    final key = SuggestionCache.keyOf(redacted, request);
    final known = cache[key];
    // Resposta já paga vale mesmo com o orçamento esgotado ou a IA fora do
    // ar: não custa nada. Só entra no cache o que passou na validação, então
    // o `!` é seguro.
    if (known != null) {
      return _merge(local, AiSuggestion.parse(known, request)!, request);
    }
    return await _consult(local, request, redacted: redacted, cacheKey: key);
  }

  Future<EntryProposal> _consult(
    EntryProposal local,
    ClassificationRequest request, {
    required String redacted,
    required String cacheKey,
  }) async {
    final month = request.today.budgetMonth;
    if (!budget.hasRoomIn(month)) return local.copyWith(warnings: ['E-AI-03']);
    if (!breaker.allowsCall) return local.copyWith(warnings: ['E-AI-01']);
    try {
      final reply = await _ask(redacted, request);
      breaker.recordSuccess();
      await budget.record(month, reply);
      final suggestion = AiSuggestion.parse(reply.content, request);
      if (suggestion == null) return local.copyWith(warnings: ['E-AI-04']);
      cache[cacheKey] = reply.content;
      return _merge(local, suggestion, request);
    } on ChatUnavailable catch (error) {
      return await _unavailable(local, request, error);
    } on TimeoutException {
      // Foto leva mais tempo por natureza: prazo vencido lendo imagem não é
      // sinal de IA fora do ar, e não desliga o assistente junto.
      if (!request.hasImages) breaker.recordFailure();
      return local.copyWith(warnings: ['E-AI-01']);
    }
  }

  /// A IA recusou o pedido, ou caiu. Recusa não é queda e não conta para o
  /// disjuntor — que é o mesmo do assistente. Pedido com foto recusado tenta
  /// uma vez só com o texto: o pedido de sempre, que a IA sabe responder.
  Future<EntryProposal> _unavailable(
    EntryProposal local,
    ClassificationRequest request,
    ChatUnavailable error,
  ) async {
    if (!error.rejected) {
      breaker.recordFailure();
      return local.copyWith(warnings: ['E-AI-01']);
    }
    if (!request.hasImages || request.text.trim().isEmpty) {
      return local.copyWith(warnings: ['E-AI-04']);
    }
    return await classify(request.withoutImages());
  }

  /// Só com texto, a pergunta de uma vez, em JSON fechado. Com a foto, a
  /// mesma pergunta numa mensagem que leva as imagens junto do texto lido.
  Future<ChatReply> _ask(String redacted, ClassificationRequest request) {
    final user = ClassificationPrompt.user(
      redacted,
      request.categories,
      examples: request.learnedRules,
    );
    if (!request.hasImages) {
      return client
          .complete(
            system: ClassificationPrompt.system,
            user: user,
            maxTokens: _maxTokens,
          )
          .timeout(timeout);
    }
    return client
        .converse(
          messages: _withImages(user, request),
          maxTokens: _maxTokensWithImages,
          json: true,
        )
        .timeout(imageTimeout);
  }

  /// As instruções, e a pergunta com as imagens junto.
  static List<ChatMessage> _withImages(
    String user,
    ClassificationRequest request,
  ) => [
    const ChatMessage.system(ClassificationPrompt.system),
    ChatMessage.user(
      user,
      images: [for (final image in request.images) ReceiptImage.dataUrl(image)],
    ),
  ];

  EntryProposal _merge(
    EntryProposal local,
    AiSuggestion ai,
    ClassificationRequest request,
  ) => ProposalMerge.of(
    local,
    ai,
    sawImage: request.hasImages,
    categoryAccuracy: categoryAccuracy,
  );
}
