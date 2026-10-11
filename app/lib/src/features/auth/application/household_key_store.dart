import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onde mora a chave da casa neste aparelho (ADR-020): o segredo único que
/// todos os aparelhos do dono apresentam ao servidor.
///
/// É uma porta porque o lugar muda com a plataforma. No Android a chave
/// vem **compilada no APK**, que só existe nas mãos do dono — instalar é
/// entrar. No navegador ela é digitada uma vez e fica guardada ali, para a
/// web não pedir nada a cada aba. No teste, é o que o teste disser.
abstract interface class HouseholdKeyStore {
  /// A chave, ou `null` quando este aparelho ainda não a tem.
  String? read();

  /// Guarda [key]. No Android não há o que guardar: a chave já veio.
  Future<void> write(String key);

  /// Esquece a chave: sair.
  Future<void> forget();

  /// Avisa quando a chave guardada muda — entrou, saiu, ou o servidor a
  /// recusou e ela foi esquecida. É o que leva a web de volta à entrada.
  Stream<void> get changes;
}

/// Onde a chave mora. A raiz do app decide.
final householdKeyProvider = Provider<HouseholdKeyStore>(
  (ref) => throw StateError('householdKeyProvider sem override na raiz.'),
);
