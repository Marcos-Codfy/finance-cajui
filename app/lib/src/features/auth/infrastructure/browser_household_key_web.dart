import 'package:cajui/src/features/auth/application/household_key_store.dart';
import 'package:web/web.dart' as web;

/// A chave da casa no navegador: digitada uma vez, guardada no
/// armazenamento local da página (ADR-020).
///
/// Fica no navegador de propósito: a web é a consulta de quem já tem a
/// casa, e pedir a chave a cada aba era a cerimônia que o dono pediu para
/// tirar. Sair apaga.
final class BrowserHouseholdKey implements HouseholdKeyStore {
  /// Cria a porta.
  const new();

  static const _slot = 'cajui.chave-da-casa';

  @override
  String? read() {
    final key = web.window.localStorage.getItem(_slot);
    return key == null || key.isEmpty ? null : key;
  }

  @override
  Future<void> write(String key) async =>
      web.window.localStorage.setItem(_slot, key.trim());

  @override
  Future<void> forget() async => web.window.localStorage.removeItem(_slot);
}
