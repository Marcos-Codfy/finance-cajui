import 'package:cajui/src/core/settings/preferences.dart';
import 'package:cajui/src/core/settings/preferences_store.dart';

/// Onde não se guarda preferência: o navegador (ADR-013).
///
/// A web é consulta, e a aba é a sessão. Guardar escolha ali seria deixar
/// rastro de quem só veio olhar — e num lugar que qualquer extensão alcança.
final class NoPreferencesStore implements PreferencesStore {
  /// Cria a porta que não guarda nada.
  const new();

  @override
  Preferences read() => const Preferences();

  @override
  Future<void> update(Preferences Function(Preferences current) change) async {}
}
