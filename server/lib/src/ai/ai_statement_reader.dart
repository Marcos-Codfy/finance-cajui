import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:server/src/ai/chat_client.dart';
import 'package:server/src/ai/chat_message.dart';
import 'package:server/src/ai/chat_reply.dart';
import 'package:server/src/ai/chat_unavailable.dart';
import 'package:server/src/ai/circuit_breaker.dart';
import 'package:server/src/ai/receipt_image.dart';
import 'package:server/src/ai/statement_answer.dart';
import 'package:server/src/ai/statement_movements.dart';
import 'package:server/src/ai/statement_prompt.dart';
import 'package:server/src/ai/suggestion_cache.dart';
import 'package:server/src/ai/token_budget.dart';
import 'package:server/src/auth/secure_random.dart';

/// O que deu a leitura de uma página: a resposta, ou o código do catálogo
/// que diz por que não houve — e quanto esperar, quando o provedor disse.
typedef StatementReadOutcome = ({
  StatementPageReply? reply,
  ErrorCode? error,
  int? retryAfterSeconds,
});

/// A página em leitura: o pedido, as linhas mascaradas de novo aqui, a
/// lista de categorias e o dia de hoje.
typedef _Page = ({
  StatementPageRequest request,
  List<String> lines,
  List<Category> categories,
  LocalDate today,
});

/// Quem lê uma página de extrato com a IA (ADR-030, RN-1102 a RN-1106).
///
/// A IA só lê; quem decide o que cada linha é, é o celular. Daqui sai só o
/// que passou nas conferências ([StatementMovements]). Resposta cortada pelo
/// teto de tokens é lida de novo em duas metades, uma vez; se cortar outra
/// vez, valem as movimentações completas, e a página sai marcada como lida
/// em parte (RN-1103). O orçamento, o disjuntor e o cache são os mesmos
/// cuidados do comprovante (RN-777, RN-778).
final class AiStatementReader {
  /// Cria o leitor.
  new({
    required this.client,
    required this.budget,
    required this.breaker,
    this.timeout = const Duration(seconds: 35),
    SuggestionCache? cache,
  }) : cache = cache ?? SuggestionCache();

  /// O modelo de linguagem.
  final ChatClient client;

  /// O teto mensal de tokens, o mesmo do comprovante e da conversa.
  final TokenBudget budget;

  /// O disjuntor, o mesmo das outras peças.
  final CircuitBreaker breaker;

  /// O prazo de cada pergunta à IA. A página cortada faz duas — a inteira
  /// e as metades, juntas —, e o celular espera pelas duas.
  final Duration timeout;

  /// As páginas já pagas: ler o mesmo extrato de novo não custa outra vez.
  final SuggestionCache cache;

  /// O teto da resposta: sessenta movimentações cabem com folga; mais que
  /// isso corta, e a página vai em metades.
  static const _maxTokens = 4000;

  /// Lê a página [request] com as [categories] da casa. [householdNames]
  /// são mascarados de novo antes da IA (RN-732).
  Future<StatementReadOutcome> read(
    StatementPageRequest request, {
    required List<Category> categories,
    required LocalDate today,
    List<String> householdNames = const [],
  }) async {
    final page = (
      request: request,
      lines: _redacted(request.lines, householdNames),
      categories: categories,
      today: today,
    );
    final key = _keyOf(page);
    // Página já paga vale mesmo sem orçamento e com a IA fora do ar.
    if (cache[key] case final known?) return _done(_cached(known, page));
    if (!budget.hasRoomIn(today.budgetMonth)) return _failed(ErrorCode.ai03);
    if (!breaker.allowsCall) return _failed(ErrorCode.ai01);
    return await _consult(page, key);
  }

  Future<StatementReadOutcome> _consult(_Page page, String key) async {
    try {
      final reply = await _readPage(page);
      breaker.recordSuccess();
      if (reply == null) return _failed(ErrorCode.ai04);
      // Página lida em parte não fica guardada: ler de novo pode render
      // a página inteira.
      if (!reply.partial) cache[key] = jsonEncode(reply.toJson());
      return _done(reply);
    } on ChatUnavailable catch (error) {
      return await _unavailable(error, page);
    } on TimeoutException {
      // Imagem leva mais tempo por natureza, e não é sinal de queda.
      if (page.request.image == null) breaker.recordFailure();
      return _failed(ErrorCode.ai01);
    }
  }

  /// As linhas limpas e mascaradas **de novo** aqui, cada uma na sua
  /// posição: o servidor não confia em ninguém para isso (RN-730, RN-1106).
  static List<String> _redacted(List<String> lines, List<String> names) =>
      PiiRedactor.redactLines([
        for (final line in lines) ReceiptText.clean(line),
      ], householdNames: names);

  /// A IA recusou o pedido, ou caiu. Recusa da imagem tenta uma vez só com
  /// o texto, que o provedor sabe ler; queda conta para o disjuntor.
  Future<StatementReadOutcome> _unavailable(
    ChatUnavailable error,
    _Page page,
  ) async {
    if (!error.rejected) {
      breaker.recordFailure();
      final wait = error.retryAfterSeconds;
      return _failed(wait == null ? ErrorCode.ai01 : ErrorCode.ai02, wait);
    }
    final request = page.request;
    if (request.image == null || page.lines.isEmpty) {
      return _failed(ErrorCode.ai04);
    }
    return await read(
      StatementPageRequest(
        lines: page.lines,
        page: request.page,
        pageCount: request.pageCount,
        period: request.period,
        examples: request.examples,
      ),
      categories: page.categories,
      today: page.today,
    );
  }

  /// A página inteira; se a resposta cortou, as duas metades (RN-1103).
  /// `null` quando a resposta inteira, sem corte, não se aproveita.
  Future<StatementPageReply?> _readPage(_Page page) async {
    final all = List.generate(page.lines.length, (index) => index + 1);
    final first = await _ask(page, all);
    if (first.truncated) return _reply(await _halves(page, all, first), page);
    final parts = StatementAnswer.of(first);
    return parts == null ? null : _reply([parts], page);
  }

  /// As linhas [numbers] em duas metades, perguntadas juntas, uma vez só.
  /// Metade cortada de novo rende o que veio completo; se as metades nem
  /// voltam, rende o que a primeira resposta trouxe completo.
  Future<List<StatementAnswerParts?>> _halves(
    _Page page,
    List<int> numbers,
    ChatReply cut,
  ) async {
    if (numbers.length < 2) return [StatementAnswer.of(cut)];
    final middle = numbers.length ~/ 2;
    try {
      final replies = await Future.wait([
        _ask(page, numbers.sublist(0, middle)),
        _ask(page, numbers.sublist(middle)),
      ]);
      return [for (final reply in replies) StatementAnswer.of(reply)];
    } on ChatUnavailable {
      return [StatementAnswer.of(cut)];
    } on TimeoutException {
      return [StatementAnswer.of(cut)];
    }
  }

  /// A resposta da página, a partir do que as respostas da IA renderam.
  /// Resposta que não se aproveitou, cortada, ou movimentação além do teto
  /// marcam a página como lida em parte — nunca em silêncio (RN-1104).
  StatementPageReply _reply(List<StatementAnswerParts?> answers, _Page page) {
    final read = answers.nonNulls.toList();
    final own = _period(
      read.map((parts) => parts.period).nonNulls.firstOrNull,
      page.today,
    );
    final movements = StatementMovements.of([
      for (final parts in read) ...parts.items,
    ], _facts(page, own));
    const most = StatementPageReply.maxMovements;
    return StatementPageReply(
      movements: movements.take(most).toList(),
      period: own,
      partial:
          read.length < answers.length ||
          read.any((parts) => parts.cut) ||
          movements.length > most,
    );
  }

  static StatementPageFacts _facts(_Page page, BudgetMonth? own) => (
    lines: page.lines,
    hasImage: page.request.image != null,
    categoryIds: {for (final category in page.categories) category.id},
    period: own ?? page.request.period ?? page.today.budgetMonth,
    today: page.today,
  );

  /// As linhas [numbers] da página, com o número de cada uma.
  Future<ChatReply> _ask(_Page page, List<int> numbers) async {
    final request = page.request;
    final user = StatementPrompt.user(
      numbered: [
        for (final number in numbers) (number, page.lines[number - 1]),
      ],
      categories: page.categories,
      page: request.page,
      pageCount: request.pageCount,
      examples: request.examples,
      period: request.period,
    );
    final reply = await _send(user, request.image).timeout(timeout);
    await budget.record(page.today.budgetMonth, reply);
    return reply;
  }

  /// Só com texto, a pergunta de uma vez, em JSON fechado. Com a imagem,
  /// a mesma pergunta numa mensagem que a leva junto.
  Future<ChatReply> _send(String user, Uint8List? image) => image == null
      ? client.complete(
          system: StatementPrompt.system,
          user: user,
          maxTokens: _maxTokens,
        )
      : client.converse(
          messages: [
            const ChatMessage.system(StatementPrompt.system),
            ChatMessage.user(user, images: [ReceiptImage.dataUrl(image)]),
          ],
          maxTokens: _maxTokens,
          json: true,
        );

  /// O mês que a página escreve, se existe e não é depois de hoje.
  static BudgetMonth? _period(String? raw, LocalDate today) {
    if (raw == null) return null;
    try {
      final month = EntryCodec.parseMonth(raw);
      return month.isAfter(today.budgetMonth) ? null : month;
    } on FormatException {
      return null;
    }
  }

  /// A chave do cache: o texto mascarado, a versão das instruções e as
  /// listas enviadas. Nem o texto nem a imagem ficam guardados, só o
  /// resumo (RN-778).
  static String _keyOf(_Page page) {
    final request = page.request;
    final image = request.image;
    final lists = jsonEncode({
      'v': StatementPrompt.version,
      'categories': [for (final category in page.categories) category.id],
      'examples': request.examples,
      'period': request.period?.toString(),
      'image': image == null ? null : SecureRandom.hash(base64Encode(image)),
    });
    return SecureRandom.hash('$lists\n${page.lines.join('\n')}');
  }

  static StatementPageReply _cached(String known, _Page page) =>
      StatementPageReply.fromJson(
        jsonDecode(known) as Map<String, Object?>,
        knowsCategory: {for (final c in page.categories) c.id}.contains,
      );

  static StatementReadOutcome _done(StatementPageReply reply) =>
      (reply: reply, error: null, retryAfterSeconds: null);

  static StatementReadOutcome _failed(ErrorCode code, [int? wait]) =>
      (reply: null, error: code, retryAfterSeconds: wait);
}
