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
    final amount = _amount(item['amountCents']);
    if (amount == null) return null;
    // Sem a foto, número fora do texto é número inventado (RN-774).
    if (!request.hasImages && !inText.contains(amount)) return null;
    final date = AiSuggestion.plausibleDate(item['occurredOn'], request);
    if (date == null) return null;
    return StatementLine(
      occurredOn: date,
      amount: amount,
      description: _description(item['description']),
      kind:
          StatementLineKind.values.asNameMap()[item['kind']] ??
          StatementLineKind.expense,
      categoryId: _category(item['categoryId'], request),
      paymentKind: PaymentMethodKind.values.asNameMap()[item['paymentKind']],
    );
  }

  /// O nome da linha passa pelo mesmo filtro do comprovante (RN-775).
  static String _description(Object? raw) =>
      ReceiptDescriptionPolicy.accepted(raw is String ? raw : null) ?? unnamed;

  /// Categoria fora da lista enviada não existe (RN-773).
  static String? _category(Object? id, ClassificationRequest request) =>
      id is String && request.categoryById(id) != null ? id : null;

  /// O valor sempre positivo: o extrato escreve saída com sinal de menos, e
  /// o sentido da linha está no tipo dela, não no sinal.
  static Money? _amount(Object? cents) {
    // Número quebrado é a IA respondendo em reais, como no comprovante.
    if (cents is! num || cents != cents.roundToDouble()) return null;
    final value = cents.round().abs();
    return value > 0 && value <= AiSuggestion.maxCents
        ? Money.fromCents(value)
        : null;
  }
}
