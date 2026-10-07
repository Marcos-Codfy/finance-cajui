import 'package:cajui/src/features/auth/application/household_key_store.dart';

/// A chave da casa como ela vem no Android: **compilada no APK** (ADR-020).
///
/// O APK é montado no PC do dono, com a chave lida de um arquivo fora do
/// repositório, e só chega aos celulares dele. Instalar é entrar: nenhuma
/// tela pede nada, nenhum código viaja. Build sem a chave — a conferência
/// do GitHub, um teste — nasce sem servidor, e o app funciona sozinho.
final class BuiltInHouseholdKey implements HouseholdKeyStore {
  /// Cria a porta.
  const new();

  /// O que `--dart-define=CAJUI_ACCESS_KEY=…` pôs no build.
  static const _compiled = String.fromEnvironment('CAJUI_ACCESS_KEY');

  @override
  String? read() => _compiled.isEmpty ? null : _compiled;

  @override
  Future<void> write(String key) async {}

  @override
  Future<void> forget() async {}
}
