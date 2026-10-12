import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/statements/application/statement_page.dart';
import 'package:cajui/src/features/statements/application/statement_page_source.dart';
import 'package:cajui/src/features/statements/application/statement_reader.dart';
import 'package:cajui/src/features/statements/application/statement_reading.dart';
import 'package:domain/domain.dart';

/// A leitura de páginas de mentira: devolve, para cada página, as
/// respostas combinadas, uma por pedido — a última se repete —, e guarda
/// cada pedido.
final class FakePageSource implements StatementPageSource {
  /// Cria a leitura com o roteiro [script]; página fora dele volta vazia.
  new([this.script = const {}]);

  /// Página → o que cada pedido dela devolve, na ordem.
  final Map<int, List<StatementPageOutcome>> script;

  /// Os pedidos, na ordem em que chegaram.
  final List<StatementPageRequest> requests = [];

  /// Os pedidos da página [page].
  Iterable<StatementPageRequest> of(int page) =>
      requests.where((request) => request.page == page);

  @override
  Future<StatementPageOutcome> read(
    StatementPageRequest request, {
    required bool Function(String id) knowsCategory,
  }) async {
    requests.add(request);
    final outcomes = script[request.page] ?? [pageRead()];
    final call = of(request.page).length - 1;
    return outcomes[call < outcomes.length ? call : outcomes.length - 1];
  }
}

/// A página lida, com [movements].
StatementPageOutcome pageRead({
  List<StatementMovement> movements = const [],
  BudgetMonth? period,
  bool partial = false,
}) => (
  reply: StatementPageReply(
    movements: movements,
    period: period,
    partial: partial,
  ),
  failure: null,
);

/// A página que não veio, pelo motivo [code].
StatementPageOutcome pageFailed(ErrorCode code) => (reply: null, failure: code);

/// Uma movimentação de outubro, na linha [line].
StatementMovement movementOn(
  int line,
  int day, {
  int month = 10,
  int cents = 1000,
}) => StatementMovement(
  sourceLine: line,
  day: day,
  month: month,
  description: 'Padaria Boa Vista',
  amount: Money.fromCents(cents),
);

/// Uma página com o texto [text]: por padrão, uma linha de compra.
StatementPage statementPage([String text = '05/10 PADARIA BOA VISTA 10,00']) =>
    StatementPage(text: text);

/// Lê [pages] sobre [source], com hoje em 11/10/2026.
Future<StatementReading> readStatement(
  FakePageSource source,
  List<StatementPage> pages, {
  int? pageCount,
  Map<String, String> examples = const {},
  HouseholdNames household = HouseholdNames.empty,
  void Function(int page, int of)? onPage,
}) => StatementReader(source, today: () => LocalDate(2026, 10, 11)).read(
  pages,
  knowsCategory: (_) => true,
  pageCount: pageCount,
  examples: examples,
  household: household,
  onPage: onPage,
);
