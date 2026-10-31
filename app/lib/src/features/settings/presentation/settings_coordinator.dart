import 'package:cajui/src/core/navigation/navigation_providers.dart';
import 'package:cajui/src/core/navigation/scene_navigator.dart';
import 'package:cajui/src/features/auth/presentation/household_key_page.dart';
import 'package:cajui/src/features/settings/presentation/household_names_page.dart';
import 'package:cajui/src/features/settings/presentation/settings_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Para onde levam os Ajustes (ADR-031).
final class SettingsCoordinator {
  /// Cria o coordinator sobre o navegador de cenas.
  const new(this._navigator);

  final SceneNavigator _navigator;

  /// Os Ajustes.
  Future<void> openSettings() => _navigator.push<void>(const SettingsPage());

  /// Os nomes da casa.
  Future<void> openHouseholdNames() =>
      _navigator.push<void>(const HouseholdNamesPage());

  /// A chave da casa, para entrar na consulta pela web de outro computador.
  Future<void> openHouseholdKey() =>
      _navigator.push<void>(const HouseholdKeyPage());
}

/// O coordinator dos Ajustes.
final settingsCoordinatorProvider = Provider<SettingsCoordinator>(
  (ref) => SettingsCoordinator(ref.watch(sceneNavigatorProvider)),
);
