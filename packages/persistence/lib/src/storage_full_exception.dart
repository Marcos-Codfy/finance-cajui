/// O aparelho ficou sem espaço para gravar o registro.
///
/// Existe como tipo próprio, e não como a `FileSystemException` crua, porque
/// quem lê isto é a tela: sem espaço é `E-STORAGE-01` e pede uma saída
/// ("Abrir armazenamento"), enquanto cadeia quebrada é `E-DATA-01` e pede
/// outra. Distinguir por texto de mensagem do sistema operacional seria
/// frágil — a mensagem muda com o idioma e com a plataforma.
final class StorageFullException implements Exception {
  /// Cria a falta de espaço, com o [path] em que ela aconteceu.
  const new(this.path);

  /// Onde o registro tentava gravar.
  final String path;

  @override
  String toString() => 'StorageFullException: sem espaço em $path';
}
