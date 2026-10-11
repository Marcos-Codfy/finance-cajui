import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:server/src/ledger/ledger_state.dart';

/// Os nomes da casa que os celulares mandaram (RN-1070), lidos dos fatos
/// do aparelho que o servidor guarda.
///
/// Existem aqui para uma coisa só: esconder esses nomes antes de qualquer
/// texto ir para a IA (RN-732, BL-093). O comprovante de um Pix para a
/// esposa e a frase ditada "mandei 500 para o Marcos" levam o nome de
/// alguém da casa; mascarado, a IA ainda entende a movimentação e não fica
/// sabendo de quem é.
abstract final class HouseholdFacts {
  /// Os nomes da lista mais nova pelo carimbo — a mesma regra dos celulares
  /// (ADR-024). Vazio quando nenhum celular mandou nomes.
  static List<String> namesIn(LedgerState state) {
    HouseholdNames? newest;
    for (final fact in state.facts) {
      if (fact.type != DeviceFact.householdNamed) continue;
      final names = HouseholdCodec.decode(fact.payload);
      final current = newest;
      if (current == null || _isNewer(names, current)) newest = names;
    }
    return newest?.names ?? const [];
  }

  static bool _isNewer(HouseholdNames candidate, HouseholdNames current) {
    final at = candidate.definedAt;
    final than = current.definedAt;
    if (at == null) return false;
    return than == null || at.isAfter(than);
  }
}
