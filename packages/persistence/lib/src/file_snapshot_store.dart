import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:persistence/src/record_cipher.dart';
import 'package:persistence/src/record_tampered_exception.dart';
import 'package:persistence/src/snapshot_store.dart';

/// Resumos em arquivo, cifrados, gravados por **arquivo temporário +
/// `rename`**.
///
/// O `rename` dentro do mesmo diretório é atômico: depois de uma queda de
/// energia, o resumo é o antigo inteiro ou o novo inteiro — nunca uma
/// mistura. É a garantia que o registro de eventos não precisa, porque só
/// acrescenta, e que o resumo precisa, porque é regravado.
final class FileSnapshotStore implements SnapshotStore {
  /// Cria o armazenamento numa pasta, cifrando com a cifra dada.
  new(this._directory, this._cipher);

  final Directory _directory;
  final RecordCipher _cipher;

  File _fileOf(String name) => File(p.join(_directory.path, '$name.snapshot'));

  @override
  Future<void> write(String name, Map<String, Object?> state) async {
    _directory.createSync(recursive: true);
    final box = await _cipher.seal(
      utf8.encode(jsonEncode(state)),
      associated: utf8.encode(name),
    );
    final content = jsonEncode({
      'v': _cipher.version,
      'n': base64Encode(box.nonce),
      'c': base64Encode(box.sealed),
    });
    final target = _fileOf(name);
    final temporary = File('${target.path}.tmp');
    final handle = await temporary.open(mode: FileMode.write);
    try {
      await handle.writeString(content);
      await handle.flush();
    } finally {
      await handle.close();
    }
    await temporary.rename(target.path);
  }

  @override
  Future<Map<String, Object?>?> read(String name) async {
    final file = _fileOf(name);
    if (!file.existsSync()) return null;
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, Object?>;
      final opened = await _cipher.open(
        nonce: base64Decode(json['n']! as String),
        sealed: base64Decode(json['c']! as String),
        // O nome entra nos dados autenticados: trocar um resumo pelo de outro
        // nome não abre.
        associated: utf8.encode(name),
      );
      return jsonDecode(utf8.decode(opened)) as Map<String, Object?>;
    } on RecordTamperedException {
      return null;
    } on FormatException {
      return null;
    }
  }
}
