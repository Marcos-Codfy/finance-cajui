import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// O que sobrou da resposta da IA depois de validada: só campos que passaram
/// em todas as conferências. O resto foi descartado, campo a campo.
@immutable
final class AiSuggestion {
  const new _({
    this.categoryId,
    this.confidence = 0,
    this.amount,
    this.occurredOn,
    this.documentKind,
    this.description,
  });

  static const _fields = {
    'categoryId',
    'confidence',
    'amountCents',
    'occurredOn',
    'documentKind',
    'description',
  };

  /// A categoria, garantidamente uma das que foram enviadas.
  final String? categoryId;

  /// A confiança que a IA **declarou**. Sozinha, nunca põe um campo na zona
  /// alta (RN-742): é só um dos ingredientes.
  final double confidence;

  /// O valor, garantidamente um número que existe no texto.
  final Money? amount;

  /// A data, garantidamente uma que existe no texto e não está no futuro.
  final LocalDate? occurredOn;

  /// O tipo do documento.
  final DocumentKind? documentKind;

  /// A descrição sugerida, já aprovada pelo filtro da RN-775; `null` quando
  /// a IA não sugeriu ou o filtro recusou.
  final String? description;

  /// Valida [content], a resposta crua da IA, contra o pedido [request].
  ///
  /// Devolve **nulo** quando a resposta inteira é inaproveitável — não é
  /// JSON, não é objeto, tem campo desconhecido ou tipo errado (RN-773):
  /// `E-AI-04`. Campo com valor fora do permitido é descartado sozinho.
  static AiSuggestion? parse(String content, ClassificationRequest request) {
    final Object? json;
    try {
      json = jsonDecode(content);
    } on FormatException {
      return null;
    }
    if (json is! Map<String, Object?>) return null;
    if (json.keys.any((key) => !_fields.contains(key))) return null;
    if (!_typesAreValid(json)) return null;
    return AiSuggestion._(
      categoryId: _category(json['categoryId'], request),
      confidence: ((json['confidence'] as num?) ?? 0).toDouble().clamp(0, 1),
      amount: _amount(json['amountCents'], request.text),
      occurredOn: _date(json['occurredOn'], request),
      documentKind: DocumentKind.values.asNameMap()[json['documentKind']],
      // O único texto livre da IA que pode chegar à tela: só passa o que tem
      // cara de nome de compra (RN-775).
      description: ReceiptDescriptionPolicy.accepted(
        json['description'] as String?,
      ),
    );
  }

  static bool _typesAreValid(Map<String, Object?> json) =>
      json['categoryId'] is String? &&
      json['confidence'] is num? &&
      json['amountCents'] is int? &&
      json['occurredOn'] is String? &&
      json['documentKind'] is String? &&
      json['description'] is String?;

  /// Categoria fora da lista enviada não existe (RN-773).
  static String? _category(Object? id, ClassificationRequest request) =>
      id is String && request.categoryById(id) != null ? id : null;

  /// O valor precisa **estar no comprovante** (RN-774): a IA não decide
  /// quanto foi gasto, só aponta para um número que o leitor local também vê.
  static Money? _amount(Object? cents, String text) {
    if (cents is! int || cents <= 0) return null;
    final money = Money.fromCents(cents);
    return ReceiptFieldReader.amountsIn(text).contains(money) ? money : null;
  }

  /// A data só vale se estiver no texto, em qualquer escrita que o leitor
  /// entende — `12/09/2026` ou `12/set/2026` (RN-774).
  static LocalDate? _date(Object? iso, ClassificationRequest request) {
    final inText = ReceiptFieldReader.datesIn(
      request.text,
      today: request.today,
    );
    // A comparação é pelo texto `AAAA-MM-DD`: data que a IA inventou, ou que
    // nem existe no calendário, simplesmente não bate com nenhuma.
    for (final date in inText) {
      if ('$date' == iso) return date;
    }
    return null;
  }
}
