import 'dart:io';

import 'package:code_metrics/code_metrics.dart';
import 'package:path/path.dart' as p;

/// Confere os limites de tamanho e as fronteiras da arquitetura em uma ou
/// mais pastas.
///
/// Uso, a partir da raiz do repositório — é o caminho relativo a ela que diz
/// que regras de camada valem para cada arquivo:
///
///     dart run tool/code_metrics/bin/check.dart
///
/// Sai com código 1 se houver violação, para servir de trava no commit e no
/// CI.
void main(List<String> arguments) {
  final roots = arguments.isEmpty ? _defaultRoots : arguments;
  final violations = <Violation>[];
  var checked = 0;

  for (final root in roots) {
    for (final file in const SourceFinder().find(Directory(root))) {
      violations.addAll(_check(file));
      checked++;
    }
  }

  violations.forEach(stdout.writeln);
  stdout.writeln(
    violations.isEmpty
        ? '$checked arquivos conferidos, nenhum limite estourado.'
        : '${violations.length} limite(s) estourado(s) em $checked arquivos.',
  );
  exitCode = violations.isEmpty ? 0 : 1;
}

/// Cada lugar em que há código escrito à mão. Pasta nova entra aqui: o que
/// fica de fora desta lista não é conferido por ninguém.
const _defaultRoots = ['app', 'packages', 'server', 'tool'];

List<Violation> _check(File file) {
  final path = p.posix.joinAll(p.split(p.relative(file.path)));
  final content = file.readAsStringSync();
  return [
    ...const FileChecker().check(
      path,
      content,
      isTest: p.split(path).contains('test'),
    ),
    ...const ArchitectureChecker().check(path, content),
  ];
}
