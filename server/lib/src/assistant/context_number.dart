import 'package:domain/domain.dart';
import 'package:meta/meta.dart';
import 'package:server/src/assistant/context_number_kind.dart';

/// Um número que o assistente pode citar, com origem, natureza e período.
///
/// É desta lista — e não do texto da IA — que sai a seção "De onde vieram os
/// números" (RN-947), e é contra ela que se confere todo valor em reais que a
/// resposta traz (RN-943).
@immutable
final class ContextNumber {
  /// Cria o número.
  const new({
    required this.id,
    required this.label,
    required this.kind,
    required this.period,
    required this.amount,
  });

  /// O identificador com que a IA cita o número.
  final String id;

  /// O que o número é, em português claro.
  final String label;

  /// Fato, plano ou projeção.
  final ContextNumberKind kind;

  /// O período a que se refere: `2026-09`.
  final String period;

  /// O valor. Sempre de uma moeda só (RN-917).
  final Money amount;

  /// O número como vai para a IA e para a tela.
  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'kind': kind.name,
    'period': period,
    'cents': amount.cents,
  };
}
