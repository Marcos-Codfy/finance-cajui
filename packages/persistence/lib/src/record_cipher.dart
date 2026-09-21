import 'dart:typed_data';

/// A cifra de um registro: o que transforma um evento em bytes ilegíveis, e
/// de volta.
///
/// É uma porta para que o algoritmo possa ser trocado sem tocar no registro
/// de eventos. A linha gravada leva a versão da cifra que a produziu.
abstract interface class RecordCipher {
  /// A versão do formato produzido por esta cifra. Vai em claro em cada
  /// linha.
  int get version;

  /// Cifra [plaintext], autenticando junto os dados [associated] — que não
  /// são cifrados, mas não podem ser alterados sem quebrar a abertura.
  ///
  /// Devolve o nonce e o texto cifrado com a marca de autenticação. O nonce
  /// é novo a cada chamada: cifrar a mesma mensagem duas vezes dá resultados
  /// diferentes.
  Future<({Uint8List nonce, Uint8List sealed})> seal(
    List<int> plaintext, {
    required List<int> associated,
  });

  /// Abre o que [seal] produziu. Lança `RecordTamperedException` se o
  /// conteúdo, o nonce ou os dados associados foram alterados.
  Future<Uint8List> open({
    required List<int> nonce,
    required List<int> sealed,
    required List<int> associated,
  });
}
