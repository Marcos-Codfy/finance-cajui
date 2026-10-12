import 'package:domain/domain.dart';
import 'package:server/src/ai/ai_suggestion.dart';

/// As movimentações de um extrato, como a IA as leu (RN-707, ADR-022).
///
/// Cada linha passa pelas mesmas conferências de um comprovante: valor
/// positivo e plausível, data que não está no futuro, categoria da lista
/// fechada, descrição que tem cara de nome de compra. Linha que não passa
/// cai fora sozinha — e não leva as outras junto.
abstract final class AiStatementLines {
  /// Quantas linhas um extrato rende, no máximo (RN-707).
  static const maxLines = 30;

  /// A descrição de uma linha que a IA não soube nomear.
  static const unnamed = 'Movimentação';

  /// As linhas de [raw], a lista crua da resposta.
  static List<StatementLine> parse(Object? raw, ClassificationRequest request) {
    if (raw is! List<Object?>) return const [];
    final inText = ReceiptFieldReader.amountsIn(request.text);
    return [
      for (final item in raw.take(maxLines)) ?_line(item, request, inText),
    ];
  }

  static StatementLine? _line(
    Object? item,
    ClassificationRequest request,
    Set<Money> inText,
  ) {
    if (item is! Map<String, Object?>) return null;
    final amount = amountOf(item['amountCents']);
    if (amount == null) return null;
    // Sem a foto, número fora do texto é número inventado (RN-774).
    if (!request.hasImages && !inText.contains(amount)) return null;
    final date = AiSuggestion.plausibleDate(item['occurredOn'], request);
    if (date == null) return null;
    final description = _description(item['description']);
    final (kind, doubtful) = kindOf(item['kind'], description);
    return StatementLine(
      occurredOn: date,
      amount: amount,
      description: description,
      kind: kind,
      categoryId: _category(item['categoryId'], request),
      paymentKind: PaymentMethodKind.values.asNameMap()[item['paymentKind']],
      doubtful: doubtful,
    );
  }

  /// O tipo da linha. A palavra escrita nela manda — "pgto fatura" é
  /// pagamento de fatura, "pix recebido" é entrada, venha a IA dizendo o que
  /// for (RN-756, RN-758, RN-759). Sem palavra, vale a IA, mas fatura e
  /// transferência que só ela viu ficam em dúvida (RN-757); e tipo que ela
  /// não deu, ou deu fora da lista, é despesa em dúvida: aparece, nunca vem
  /// marcada. [written] é o que a linha diz: o texto dela, ou a descrição
  /// quando não há o texto. Serve também à leitura por página (RN-1110).
  static (StatementLineKind, bool) kindOf(Object? raw, String written) {
    final byWords = _byWords[ReceiptFieldReader.documentKindIn(written)];
    if (byWords != null) return (byWords, false);
    return switch (StatementLineKind.values.asNameMap()[raw]) {
      StatementLineKind.expense => (StatementLineKind.expense, false),
      StatementLineKind.income => (StatementLineKind.income, false),
      final StatementLineKind other => (other, true),
      null => (StatementLineKind.expense, true),
    };
  }

  static const Map<DocumentKind, StatementLineKind> _byWords = {
    DocumentKind.statementPayment: StatementLineKind.cardPayment,
    DocumentKind.incomeReceipt: StatementLineKind.income,
    DocumentKind.ownTransfer: StatementLineKind.ownTransfer,
  };

  /// O nome da linha passa pelo mesmo filtro do comprovante (RN-775).
  static String _description(Object? raw) =>
      ReceiptDescriptionPolicy.accepted(raw is String ? raw : null) ?? unnamed;

  /// Categoria fora da lista enviada não existe (RN-773).
  static String? _category(Object? id, ClassificationRequest request) =>
      id is String && request.categoryById(id) != null ? id : null;

  /// O valor sempre positivo: o extrato escreve saída com sinal de menos, e
  /// o sentido da linha está no tipo dela, não no sinal. De R$ 0,01 a
  /// R$ 1.000.000,00; fora disso, `null`.
  static Money? amountOf(Object? cents) {
    // Número quebrado é a IA respondendo em reais, como no comprovante; e o
    // infinito não vira centavo nenhum.
    if (cents is! num || !cents.isFinite) return null;
    if (cents != cents.roundToDouble()) return null;
    final value = cents.round().abs();
    return value > 0 && value <= AiSuggestion.maxCents
        ? Money.fromCents(value)
        : null;
  }
}
