import 'package:domain/src/receipts/confidence.dart';
import 'package:domain/src/receipts/field_source.dart';
import 'package:meta/meta.dart';

/// Um campo da proposta: o valor, de onde veio e o quanto se confia nele
/// (RN-741).
@immutable
final class ProposedField<T> {
  /// Campo lido com segurança: vem preenchido.
  const new resolved(T this.value, {required this.source})
    : candidates = const [],
      confidence = Confidence.high;

  /// O app ficou entre [candidates] e **não escolhe**: nenhum vem marcado
  /// (RN-744).
  const new undecided(this.candidates, {required this.source})
    : value = null,
      confidence = Confidence.medium;

  /// Ninguém conseguiu ler o campo.
  const new unread()
    : value = null,
      candidates = const [],
      confidence = Confidence.low,
      source = FieldSource.none;

  /// O valor proposto; nulo fora da zona alta.
  final T? value;

  /// Os candidatos da zona média, do mais provável para o menos.
  final List<T> candidates;

  /// A zona de confiança.
  final Confidence confidence;

  /// De onde o valor veio.
  final FieldSource source;
}
