import 'dart:io';

import 'package:path/path.dart' as p;

/// Acha os arquivos Dart escritos à mão debaixo de uma pasta.
///
/// Fica de fora o que não é do projeto ou não foi escrito por gente: saída
/// de build, cache de ferramenta, código gerado e as pastas de plataforma.
class SourceFinder {
  /// Cria o buscador.
  const new();

  static const _skippedFolders = {
    '.dart_tool',
    '.git',
    'build',
    'android',
    'ios',
    'web',
    'windows',
    'linux',
    'macos',
  };

  static const _generatedSuffixes = ['.g.dart', '.freezed.dart', '.gen.dart'];

  /// Os arquivos Dart debaixo de [root], em ordem alfabética.
  List<File> find(Directory root) {
    final files = <File>[];
    _walk(root, files);
    return files..sort((a, b) => a.path.compareTo(b.path));
  }

  void _walk(Directory folder, List<File> files) {
    for (final entity in folder.listSync(followLinks: false)) {
      final name = p.basename(entity.path);
      if (entity is Directory && !_skippedFolders.contains(name)) {
        _walk(entity, files);
      } else if (entity is File && _isHandWritten(name)) {
        files.add(entity);
      }
    }
  }

  bool _isHandWritten(String name) =>
      name.endsWith('.dart') && !_generatedSuffixes.any(name.endsWith);
}
