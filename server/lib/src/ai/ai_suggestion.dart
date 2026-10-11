import 'dart:convert';

import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:meta/meta.dart';
import 'package:server/src/ai/ai_statement_lines.dart';

/// O que sobrou da resposta da IA depois de validada: só campos que passaram
/// em todas as conferências. O resto foi descartado, campo a campo.
///
/// Com a foto (ADR-022), a IA lê o que o celular não leu: valor e data que
/// não aparecem no texto passam a valer, porque vieram da imagem. Só com
/// texto, continuam valendo só se estão nele (RN-774) — sem imagem, número
/// fora do texto é número inventado.
@immutable
final class AiSuggestion {
  const new _({
    this.categoryId,
    this.confidence = 0,
    this.amount,
    this.amountInText = false,
    this.occurredOn,
    this.documentKind,
    this.description,
    this.paymentKind,
    this.installments,
    this.lines = const [],
  });

  static const _fields = {
    'categoryId',
    'confidence',
    'amountCents',
    'occurredOn',
    'documentKind',
    'description',
    'paymentKind',
    'installments',
    'lines',
  };

  /// O maior valor aceito: R$ 1.000.000,00. Acima disso é leitura errada.
  static const maxCents = 100000000;

  /// Quanto tempo para trás uma data lida da imagem ainda vale.
  static const maxAgeDays = 730;

  /// A categoria, garantidamente uma das que foram enviadas.
  final String? categoryId;

  /// A confiança que a IA **declarou** na categoria.
  final double confidence;

  /// O valor.
  final Money? amount;

  /// Se [amount] aparece no texto que o celular leu — o que o confirma.
  final bool amountInText;

  /// A data, que não está no futuro.
  final LocalDate? occurredOn;

  /// O tipo do documento.
  final DocumentKind? documentKind;

  /// A descrição sugerida, já aprovada pelo filtro da RN-775.
  final String? description;

  /// Por onde foi pago.
  final PaymentMethodKind? paymentKind;

  /// Em quantas vezes, quando foi parcelado.
  final int? installments;

  /// As movimentações, quando o documento é um extrato (RN-707).
  final List<StatementLine> lines;

  /// Valida [content], a resposta crua da IA, contra o pedido [request].
  ///
  /// Devolve **nulo** quando a resposta inteira é inaproveitável — não é
  /// JSON, não é objeto, tem campo desconhecido ou tipo errado (RN-773):
  /// `E-AI-04`. Campo com valor fora do permitido é descartado sozinho.
  static AiSuggestion? parse(String content, ClassificationRequest request) {
    final json = _object(content);
    if (json == null) return null;
    if (json.keys.any((key) => !_fields.contains(key))) return null;
    if (!_typesAreValid(json)) return null;
    final money = _money(json['amountCents']);
    final inText =
        money != null &&
        ReceiptFieldReader.amountsIn(request.text).contains(money);
    return AiSuggestion._(
      categoryId: _category(json['categoryId'], request),
      confidence: ((json['confidence'] as num?) ?? 0).toDouble().clamp(0, 1),
      amount: inText || request.hasImages ? money : null,
      amountInText: inText,
      occurredOn: plausibleDate(json['occurredOn'], request),
      documentKind: DocumentKind.values.asNameMap()[json['documentKind']],
      // O único texto livre da IA que pode chegar à tela: só passa o que tem
      // cara de nome de compra (RN-775).
      description: ReceiptDescriptionPolicy.accepted(
        json['description'] as String?,
      ),
      paymentKind: PaymentMethodKind.values.asNameMap()[json['paymentKind']],
      installments: _installments(json['installments']),
      lines: AiStatementLines.parse(json['lines'], request),
    );
  }

  /// O objeto da resposta. Um modelo que embrulha o JSON em bloco de código
  /// ainda é lido: vale o trecho entre a primeira e a última chave.
  static Map<String, Object?>? _object(String content) {
    final start = content.indexOf('{');
    final end = content.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final decoded = jsonDecode(content.substring(start, end + 1));
      return decoded is Map<String, Object?> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static bool _typesAreValid(Map<String, Object?> json) =>
      json['categoryId'] is String? &&
      json['confidence'] is num? &&
      json['amountCents'] is num? &&
      json['occurredOn'] is String? &&
      json['documentKind'] is String? &&
      json['description'] is String? &&
      json['paymentKind'] is String? &&
      json['installments'] is num? &&
      json['lines'] is List<Object?>?;

  /// Categoria fora da lista enviada não existe (RN-773).
  static String? _category(Object? id, ClassificationRequest request) =>
      id is String && request.categoryById(id) != null ? id : null;

  static Money? _money(Object? cents) {
    // Número quebrado é a IA respondendo em reais: 23.9 viraria R$ 0,24. E o
    // infinito (1e400 no JSON) derrubaria a conta inteira.
    if (cents is! num || !cents.isFinite) return null;
    if (cents != cents.roundToDouble()) return null;
    final rounded = cents.round();
    return rounded > 0 && rounded <= maxCents ? Money.fromCents(rounded) : null;
  }

  /// A data do texto, em qualquer escrita que o leitor entende; sem ela, e
  /// com a foto, a data que a IA leu da imagem — se não estiver no futuro
  /// nem velha demais para ser compra de agora.
  static LocalDate? plausibleDate(Object? iso, ClassificationRequest request) {
    final inText = ReceiptFieldReader.datesIn(
      request.text,
      today: request.today,
    );
    for (final date in inText) {
      if ('$date' == iso) return date;
    }
    if (!request.hasImages || iso is! String) return null;
    final LocalDate read;
    try {
      read = EntryCodec.parseDate(iso);
    } on FormatException {
      return null;
    }
    final oldest = request.today.addDays(-maxAgeDays);
    if (read.isAfter(request.today) || read.isBefore(oldest)) return null;
    return read;
  }

  static int? _installments(Object? raw) {
    if (raw is! num || !raw.isFinite) return null;
    final count = raw.round();
    return count >= 2 && count <= 48 ? count : null;
  }
}
