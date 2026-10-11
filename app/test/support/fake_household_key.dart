import 'dart:async';

import 'package:cajui/src/features/auth/application/household_key_store.dart';

/// A chave da casa de mentira: nasce com a chave dada — ou sem nenhuma,
/// como o navegador antes de entrar — e guarda o que a tela escrever.
final class FakeHouseholdKey implements HouseholdKeyStore {
  /// Cria o dublê com [key], ou sem chave quando `null`.
  new([this.key = 'chave-da-casa-de-teste-com-tamanho-bom']);

  /// A chave guardada agora.
  String? key;

  @override
  String? read() => key;

  final _changes = StreamController<void>.broadcast();

  @override
  Future<void> write(String value) async {
    key = value.trim();
    _changes.add(null);
  }

  @override
  Future<void> forget() async {
    key = null;
    _changes.add(null);
  }

  @override
  Stream<void> get changes => _changes.stream;
}
