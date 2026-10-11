import 'package:cajui/src/features/auth/application/household_key_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Guarda se a chave da casa está presente, para a casca do app reagir à
/// entrada: na web, é o que faz a tela de entrada dar lugar ao app.
class HouseholdKeyPresence extends Notifier<bool> {
  @override
  bool build() {
    final store = ref.watch(householdKeyProvider);
    final changes = store.changes.listen((_) => refresh());
    ref.onDispose(changes.cancel);
    return store.read() != null;
  }

  /// Confere de novo o que está guardado.
  void refresh() => state = ref.read(householdKeyProvider).read() != null;
}

/// Se há chave agora. Nasce do que está guardado e muda quando a pessoa
/// entra ou sai.
final hasHouseholdKeyProvider = NotifierProvider<HouseholdKeyPresence, bool>(
  HouseholdKeyPresence.new,
);
