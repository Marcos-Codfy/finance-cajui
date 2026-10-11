import 'package:cajui/src/features/auth/application/household_key_store.dart';

/// O lugar da chave do navegador onde não há navegador. Nunca é usada: no
/// Android a raiz liga a chave compilada. Existe para o arquivo que escolhe
/// a implementação pela plataforma compilar nos dois mundos.
final class BrowserHouseholdKey implements HouseholdKeyStore {
  /// Cria a porta vazia.
  const new();

  @override
  String? read() => null;

  @override
  Future<void> write(String key) async {}

  @override
  Future<void> forget() async {}

  @override
  Stream<void> get changes => const Stream.empty();
}
