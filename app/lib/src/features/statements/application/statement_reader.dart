import 'dart:math';

import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/statements/application/missed_lines.dart';
import 'package:cajui/src/features/statements/application/numbered_page.dart';
import 'package:cajui/src/features/statements/application/statement_page.dart';
import 'package:cajui/src/features/statements/application/statement_page_source.dart';
import 'package:cajui/src/features/statements/application/statement_reading.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lê um extrato com a IA do servidor, uma página por pedido (ADR-030,
/// RN-1101 a RN-1104).
///
/// O laço é daqui, e não do servidor: várias leituras de 35 s num pedido
/// só estourariam o prazo do celular, e assim a conversa diz "Lendo a
/// página 3 de 7". Cada página sai daqui mascarada (RN-730, RN-1106) — o
/// texto original fica no resultado, para o celular achar o nome de verdade
/// pelo número da linha. Página que falha é tentada mais uma vez; se falhar
/// de novo, as outras seguem, e o resultado diz qual ficou de fora.
final class StatementReader {
  /// Cria o caso de uso sobre a leitura de páginas; `today` diz o dia,
  /// para recusar data no futuro (RN-1105).
  const new(this._source, {required this._today});

  final StatementPageSource _source;
  final LocalDate Function() _today;

  /// Quantas movimentações um extrato rende (RN-1104). O que passar disso
  /// é dito no resultado, nunca cortado em silêncio.
  static const maxLines = 400;

  /// Falhas que valem para todas as páginas: sem orçamento de IA, sem a
  /// chave da casa, ou o provedor pedindo pausa (E-AI-02, o 429). Tentar de
  /// novo, ou ler a página seguinte, só gastaria pedidos — e, no caso da
  /// pausa, cada pedido recusado conta no disjuntor do servidor, que é o
  /// mesmo do chat e do comprovante: insistir página após página o abriria
  /// para o resto do app.
  static const Set<ErrorCode> _forAllPages = {
    ErrorCode.ai02,
    ErrorCode.ai03,
    ErrorCode.auth03,
  };

  /// Lê [pages], na ordem. [pageCount] é o total real dos arquivos, quando
  /// passa do que foi lido; [examples] são as respostas lembradas, chave
  /// do estabelecimento → categoria; [household], os nomes que não saem do
  /// celular; [onPage] recebe "página x de y".
  Future<StatementReading> read(
    List<StatementPage> pages, {
    required bool Function(String id) knowsCategory,
    int? pageCount,
    Map<String, String> examples = const {},
    HouseholdNames household = HouseholdNames.empty,
    void Function(int page, int of)? onPage,
  }) async {
    final reading = _Reading(
      pages: pages,
      numbered: [
        for (final page in pages)
          NumberedPage.of(page.text, household: household),
      ],
      examples: _withoutPeople(examples),
    );
    for (var number = 1; number <= pages.length; number++) {
      onPage?.call(number, pages.length);
      await _readPage(reading, number, knowsCategory);
    }
    return reading.result(pageCount: pageCount ?? 0, today: _today());
  }

  /// A página [number], tentada mais uma vez se falhar (RN-1102). Página
  /// sem texto e sem imagem não tem o que mandar: fica de fora, dita.
  Future<void> _readPage(
    _Reading reading,
    int number,
    bool Function(String id) knows,
  ) async {
    final halted = reading.halted;
    final request = reading.requestFor(number);
    if (halted != null || (request.lines.isEmpty && request.image == null)) {
      reading.fail(number, halted ?? ErrorCode.capt01);
      return;
    }
    var outcome = await _source.read(request, knowsCategory: knows);
    if (outcome.reply == null && !_forAllPages.contains(outcome.failure)) {
      outcome = await _source.read(request, knowsCategory: knows);
    }
    final reply = outcome.reply;
    if (reply == null) {
      reading.fail(number, outcome.failure ?? ErrorCode.app01);
    } else {
      reading.add(number, await _withMissed(reading, request, reply, knows));
    }
  }

  /// [reply] com as linhas de data e valor que ela não citou pedidas de
  /// novo, uma vez só; o que ainda faltar fica contado, para a conversa
  /// dizer (RN-1104). Resposta sem movimentação nenhuma não é repetida:
  /// pedir as mesmas linhas de novo seria o mesmo pedido.
  Future<StatementPageReply> _withMissed(
    _Reading reading,
    StatementPageRequest request,
    StatementPageReply reply,
    bool Function(String id) knows,
  ) async {
    final page = reading.numbered[request.page - 1];
    final missed = MissedLines.of(page, reply);
    if (missed.isEmpty || reply.movements.isEmpty) {
      reading.unread[request.page] = missed.length;
      return reply;
    }
    final again = await _source.read(
      MissedLines.retry(request, missed),
      knowsCategory: knows,
    );
    final extra = again.reply;
    final merged = extra == null
        ? reply
        : MissedLines.merged(reply, extra, missed, page);
    reading.unread[request.page] = MissedLines.of(page, merged).length;
    return merged;
  }

  /// Resposta lembrada que fala de pessoa nunca vira exemplo para a IA
  /// (RN-1107) — mesmo que alguém a tenha posto na lista. Não basta o
  /// prefixo "pessoa:": a regra antiga do comprovante guardava o nome solto
  /// ("joao p silva"), e é o domínio que diz se a chave tem cara de gente.
  static Map<String, String> _withoutPeople(Map<String, String> examples) => {
    for (final MapEntry(:key, :value) in examples.entries)
      if (!key.startsWith(StatementLineResolver.personPrefix) &&
          !LearnedRules.looksLikePerson(key))
        key: value,
  };
}

/// Uma leitura em curso: as páginas, as respostas que voltaram e as que
/// falharam, na ordem das páginas.
final class _Reading {
  new({required this.pages, required this.numbered, required this.examples});

  final List<StatementPage> pages;
  final List<NumberedPage> numbered;
  final Map<String, String> examples;
  final Map<int, StatementPageReply> replies = {};
  final Map<int, ErrorCode> failures = {};

  /// Quantas linhas com data e valor de cada página não vieram, nem
  /// pedindo de novo.
  final Map<int, int> unread = {};

  /// A falha que vale para todas as páginas, se já houve uma.
  ErrorCode? get halted =>
      failures.values.where(StatementReader._forAllPages.contains).firstOrNull;

  /// O mês que a primeira página que o escreve disse.
  BudgetMonth? get period =>
      replies.values.map((reply) => reply.period).nonNulls.firstOrNull;

  /// O pedido da página [number], com o mês já sabido.
  StatementPageRequest requestFor(int number) => StatementPageRequest(
    lines: numbered[number - 1].masked,
    page: number,
    pageCount: pages.length,
    image: pages[number - 1].imageForAi,
    period: period,
    examples: examples,
  );

  void add(int number, StatementPageReply reply) => replies[number] = reply;

  void fail(int number, ErrorCode code) => failures[number] = code;

  /// O resultado. O período é o que uma página disse; senão o mês da
  /// maioria das datas (RN-1105). [pageCount] menor que o lido vale o lido.
  StatementReading result({required int pageCount, required LocalDate today}) {
    final period =
        this.period ??
        StatementDates.prevailing([
          for (final reply in replies.values)
            for (final movement in reply.movements) movement.month,
        ], today: today);
    final lines = _lines(period ?? today.budgetMonth, today);
    const most = StatementReader.maxLines;
    return StatementReading(
      lines: lines.take(most).toList(),
      originals: [for (final page in numbered) page.original],
      period: period,
      pageCount: max(pageCount, pages.length),
      pagesRead: pages.length,
      failedPages: failures.keys.toList(),
      partialPages: [
        for (final MapEntry(:key, :value) in replies.entries)
          if (value.partial) key,
      ],
      beyondLimit: max(0, lines.length - most),
      unreadLines: unread.values.fold(0, (sum, count) => sum + count),
      failure: failures.values.lastOrNull,
    );
  }

  /// As movimentações das páginas, na ordem, com a data resolvida no
  /// período; a que cai no futuro fica de fora (RN-1105).
  List<StatementLine> _lines(BudgetMonth period, LocalDate today) => [
    for (final MapEntry(key: page, value: reply) in replies.entries)
      for (final movement in reply.movements)
        ?movement.lineOn(page: page, period: period, today: today),
  ];
}

/// O caso de uso, sobre a leitura de páginas que a raiz do app ligar.
final statementReaderProvider = Provider<StatementReader>(
  (ref) => StatementReader(
    ref.watch(statementPageSourceProvider),
    today: ref.watch(clockProvider).today,
  ),
);
