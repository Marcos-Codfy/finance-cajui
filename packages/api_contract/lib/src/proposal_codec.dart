import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

/// A ida e a volta da **proposta** de um comprovante: o que a leitura
/// resolveu, o que ficou em dúvida e de onde cada coisa veio.
///
/// Mora no contrato porque os dois lados a usam: o servidor a escreve em
/// `POST /v1/receipts/classify` e o aparelho a lê. Cada campo leva a **zona
/// de confiança** junto (RN-741) — sem isso o app não saberia o que pode vir
/// preenchido e o que precisa vir como pergunta.
abstract final class ProposalCodec {
  /// A proposta como vai na resposta.
  static Map<String, Object?> encode(EntryProposal proposal) => {
    'documentKind': _encode(proposal.documentKind, (kind) => kind.name),
    'amountCents': _encode(proposal.amount, (money) => money.cents),
    'occurredOn': _encode(proposal.occurredOn, (date) => '$date'),
    'categoryId': _encode(proposal.category, (id) => id),
    'paymentKind': _encode(proposal.paymentKind, (kind) => kind.name),
    'merchant': proposal.merchant,
    'description': proposal.description,
    'installments': proposal.installments,
    'warnings': proposal.warnings,
  };

  /// A proposta que o servidor devolveu.
  ///
  /// Nada aqui é confiado de olhos fechados: valor, data e categoria passam
  /// pelos mesmos leitores do resto do contrato, e categoria que o aparelho
  /// não conhece cai fora — a lista é fechada (RN-742).
  static EntryProposal decode(
    Map<String, Object?> json, {
    required bool Function(String id) knowsCategory,
  }) => EntryProposal(
    documentKind: _decode(
      json['documentKind'],
      (raw) => EntryCodec.named(DocumentKind.values, '$raw'),
    ),
    amount: _decode(json['amountCents'], (raw) => Money.fromCents(raw! as int)),
    occurredOn: _decode(
      json['occurredOn'],
      (raw) => EntryCodec.parseDate('$raw'),
    ),
    category: _decode(json['categoryId'], _onlyKnown(knowsCategory)),
    paymentKind: _decode(
      json['paymentKind'],
      (raw) => EntryCodec.named(PaymentMethodKind.values, '$raw'),
    ),
    merchant: json['merchant'] as String?,
    description: json['description'] as String?,
    installments: json['installments'] as int?,
    warnings: [
      for (final warning in json['warnings'] as List<Object?>? ?? const [])
        '$warning',
    ],
  );

  /// Categoria que este aparelho não conhece cai fora: a lista é fechada
  /// (RN-742), e inventar uma seria pior do que deixar o campo em branco.
  static String Function(Object?) _onlyKnown(bool Function(String) knows) =>
      (raw) => knows('$raw')
      ? '$raw'
      : throw const FormatException('categoria desconhecida');

  static Map<String, Object?> _encode<T>(
    ProposedField<T> field,
    Object Function(T value) encode,
  ) {
    final value = field.value;
    return {
      'value': value == null ? null : encode(value),
      'candidates': field.candidates.map(encode).toList(),
      'confidence': field.confidence.name,
      'source': field.source.name,
    };
  }

  /// Campo que não vier no formato esperado volta como **não lido**, e não
  /// derruba a proposta inteira: um campo a menos ainda é uma tela que dá
  /// para conferir (RN-747).
  static ProposedField<T> _decode<T>(
    Object? raw,
    T Function(Object? value) read,
  ) {
    if (raw is! Map<String, Object?>) return ProposedField<T>.unread();
    final source = _sourceOf(raw['source']);
    final candidates = [
      for (final item in raw['candidates'] as List<Object?>? ?? const [])
        ?_tried(item, read),
    ];
    final value = _tried(raw['value'], read);
    if (value != null) return ProposedField<T>.resolved(value, source: source);
    if (candidates.isEmpty) return ProposedField<T>.unread();
    return ProposedField<T>.undecided(candidates, source: source);
  }

  static T? _tried<T>(Object? raw, T Function(Object? value) read) {
    if (raw == null) return null;
    try {
      return read(raw);
    } on Object {
      return null;
    }
  }

  static FieldSource _sourceOf(Object? raw) =>
      FieldSource.values.where((s) => s.name == '$raw').firstOrNull ??
      FieldSource.none;
}
