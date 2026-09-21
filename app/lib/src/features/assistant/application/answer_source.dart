import 'package:meta/meta.dart';

/// Um número que a resposta usou, como o servidor o descreve: o que é, de
/// que período, e se é fato, plano ou projeção (RN-918, RN-947).
///
/// Vem do servidor, e não do texto da IA — por isso dá para confiar nele
/// mesmo quando a redação da IA é fraca.
@immutable
final class AnswerSource {
  /// Cria a origem.
  const new({
    required this.label,
    required this.cents,
    required this.kind,
    required this.period,
  });

  /// Lê a origem de [json], como vem da API.
  factory fromJson(Map<String, Object?> json) => AnswerSource(
    label: json['label']! as String,
    cents: json['cents']! as int,
    kind: json['kind']! as String,
    period: json['period']! as String,
  );

  /// O que o número é.
  final String label;

  /// O valor, em centavos.
  final int cents;

  /// `fact`, `plan` ou `projection`.
  final String kind;

  /// O período: `2026-09`.
  final String period;

  /// A natureza do número, em português.
  String get kindLabel => switch (kind) {
    'plan' => 'plano',
    'projection' => 'projeção',
    _ => 'fato',
  };
}
