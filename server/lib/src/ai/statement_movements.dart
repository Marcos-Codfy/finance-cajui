import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:server/src/ai/ai_statement_lines.dart';

/// O que a conferência de uma página precisa saber: as linhas como a IA as
/// viu (já mascaradas), se a imagem foi junto, as categorias da lista, o
/// mês do extrato e o dia de hoje.
typedef StatementPageFacts = ({
  List<String> lines,
  bool hasImage,
  Set<String> categoryIds,
  BudgetMonth period,
  LocalDate today,
});

/// O valor e a data de uma movimentação, como a IA os escreveu.
typedef _Numbers = ({Money amount, int day, int month, int? year});

/// As movimentações de uma página de extrato, como a IA as leu, depois da
/// conferência (ADR-030).
///
/// Cada uma passa pelas conferências do comprovante: o valor está escrito
/// na linha que a IA citou — ou noutra da página, e aí a linha certa é a
/// que o mostra (RN-774); a data está escrita na página e não cai no futuro
/// (RN-1105); o nome é a marca conhecida ou passa pelo filtro (RN-775,
/// RN-1108); a palavra escrita manda no tipo (RN-1110); a categoria é da
/// lista (RN-773). A que não passa cai fora sozinha.
abstract final class StatementMovements {
  /// As movimentações de [raw], a lista crua da IA, conferidas contra
  /// [page]. A mesma linha citada duas vezes com o mesmo valor entra uma
  /// vez só: é a mesma movimentação lida de novo.
  static List<StatementMovement> of(
    Iterable<Object?> raw,
    StatementPageFacts page,
  ) {
    final seen = <String>{};
    final text = page.lines.join('\n');
    final movements = <StatementMovement>[];
    for (final item in raw) {
      final movement = item is Map<String, Object?>
          ? _movement(item, page, text)
          : null;
      if (movement == null) continue;
      final line = movement.sourceLine;
      if (line != null && !seen.add('$line-${movement.amount.cents}')) continue;
      movements.add(movement);
    }
    return movements;
  }

  static StatementMovement? _movement(
    Map<String, Object?> item,
    StatementPageFacts page,
    String text,
  ) {
    final numbers = _numbers(item);
    if (numbers == null) return null;
    final line = _sourceLine(_int(item['line']), numbers.amount, page);
    if (line == null && !page.hasImage) return null;
    final written = line == null ? '' : page.lines[line - 1];
    if (!_dateFits(numbers, written, text, page)) return null;
    final description = _description(item['description'], written);
    final (kind, doubtful) = _kind(item['kind'], written, description);
    return StatementMovement(
      sourceLine: line,
      day: numbers.day,
      month: numbers.month,
      year: numbers.year,
      description: description,
      amount: numbers.amount,
      kind: kind,
      doubtful: doubtful,
      categoryId: _category(item['categoryId'], page),
      confidence:
          Confidence.values.asNameMap()[item['confidence']] ?? Confidence.low,
      paymentKind: PaymentMethodKind.values.asNameMap()[item['paymentKind']],
    );
  }

  /// O valor e o dia e mês, quando os três se leem. O ano só vale quando é
  /// um ano de verdade; senão a data segue o mês do extrato.
  static _Numbers? _numbers(Map<String, Object?> item) {
    final amount = AiStatementLines.amountOf(item['amountCents']);
    final day = _int(item['day']);
    final month = _int(item['month']);
    if (amount == null || day == null || month == null) return null;
    final year = _int(item['year']);
    final real = year != null && year >= 2000 && year <= 2100;
    return (amount: amount, day: day, month: month, year: real ? year : null);
  }

  /// A linha que mostra o valor: a citada, se mostra; senão a mais perto
  /// dela que mostra — duas compras iguais na mesma página ficam cada uma
  /// na sua. Sem nenhuma, só a imagem pode tê-lo mostrado: vale a citada,
  /// se existe, e o valor só passa com a imagem junto.
  static int? _sourceLine(int? cited, Money amount, StatementPageFacts page) {
    final count = page.lines.length;
    bool shows(int number) =>
        ReceiptFieldReader.amountsIn(page.lines[number - 1]).contains(amount);
    final valid = cited != null && cited >= 1 && cited <= count;
    if (valid && shows(cited)) return cited;
    final showing = [
      for (var number = 1; number <= count; number++)
        if (shows(number)) number,
    ];
    if (showing.isEmpty) return page.hasImage && valid ? cited : null;
    final anchor = cited ?? 1;
    int distance(int number) => (number - anchor).abs();
    showing.sort((a, b) => distance(a).compareTo(distance(b)));
    return showing.first;
  }

  /// A data existe, não cai depois de hoje, e está escrita na linha — ou
  /// na página, no cabeçalho de data dos extratos que agrupam por dia.
  /// Com a imagem, basta existir: o texto lido veio fraco.
  static bool _dateFits(
    _Numbers numbers,
    String written,
    String text,
    StatementPageFacts page,
  ) {
    final (:day, :month, :year, amount: _) = numbers;
    final date = StatementDates.resolve(
      day: day,
      month: month,
      year: year,
      period: page.period,
      today: page.today,
    );
    if (date == null) return false;
    if (page.hasImage) return true;
    return StatementDates.writtenIn(written, day: day, month: month) ||
        StatementDates.writtenIn(text, day: day, month: month);
  }

  /// A marca conhecida pelo que a linha escreve; senão o nome da IA, sem a
  /// maquininha, se passar pelo filtro — "NETFLIX.COM" é Netflix, e não
  /// "Movimentação" (RN-1108).
  static String _description(Object? raw, String written) {
    final ai = raw is String ? raw : '';
    final brand = MerchantBrand.of(written) ?? MerchantBrand.of(ai);
    if (brand != null) return brand.name;
    return ReceiptDescriptionPolicy.accepted(
          MerchantBrand.withoutAcquirer(ai),
        ) ??
        AiStatementLines.unnamed;
  }

  /// A palavra escrita na linha manda no tipo; sem a linha, vale o nome.
  static (StatementLineKind, bool) _kind(
    Object? raw,
    String written,
    String description,
  ) => AiStatementLines.kindOf(raw, written.isEmpty ? description : written);

  static String? _category(Object? id, StatementPageFacts page) =>
      id is String && page.categoryIds.contains(id) ? id : null;

  static int? _int(Object? raw) =>
      raw is num && raw.isFinite && raw == raw.roundToDouble()
      ? raw.round()
      : null;
}
