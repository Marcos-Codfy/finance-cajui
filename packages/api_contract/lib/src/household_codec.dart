import 'package:domain/domain.dart';

/// A ida e a volta dos nomes da casa com o registro — o do aparelho e o do
/// servidor, que os guarda para o outro celular (RN-1070, ADR-019).
///
/// O motor que lê as notificações do banco em segundo plano precisa dos
/// nomes no aparelho: por isso eles moram no livro, e não numa preferência
/// que só um celular conhece.
abstract final class HouseholdCodec {
  /// O que gravar para [names]. A lista precisa do carimbo: é ele que dá o
  /// identificador do fato e decide entre dois celulares.
  static Map<String, Object?> encode(HouseholdNames names) => {
    'names': [...names.names],
    'definedAt': names.definedAt!.toUtc().toIso8601String(),
  };

  /// Os nomes gravados em [payload]. Recusa o que o domínio não aceitaria:
  /// lista grande demais, nome sem sobrenome ou longo demais, sem carimbo —
  /// o servidor guarda o que recebe, e conferir é a única barreira (T-05).
  static HouseholdNames decode(Map<String, Object?> payload) {
    final raw = payload['names'];
    final at = payload['definedAt'];
    if (raw is! List || raw.length > HouseholdNames.maxNames || at is! String) {
      throw const FormatException('nomes da casa');
    }
    return HouseholdNames(
      names: [for (final name in raw) _name(name)],
      definedAt: DateTime.parse(at).toUtc(),
    );
  }

  static String _name(Object? raw) {
    if (raw is! String || !HouseholdNames.accepts(raw)) {
      throw const FormatException('nome da casa');
    }
    return raw.trim();
  }
}
