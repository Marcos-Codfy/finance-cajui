import 'dart:io';

import 'package:code_metrics/code_metrics.dart';
import 'package:path/path.dart' as p;

/// Confere os limites de tamanho em uma ou mais pastas.
///
/// Uso, a partir da raiz do repositório:
///
///     dart run tool/code_metrics/bin/check.dart packages tool
///
/// Sai com código 1 se houver violação, para servir de trava no commit e no
/// CI.
void main(List<String> arguments) {
  final roots = arguments.isEmpty ? ['packages', 'tool'] : arguments;
  final violations = <Violation>[];
  var checked = 0;

  for (final root in roots) {
    for (final file in const SourceFinder().find(Directory(root))) {
      final path = p.posix.joinAll(p.split(p.relative(file.path)));
      violations.addAll(
        const FileChecker().check(
          path,
          file.readAsStringSync(),
          isTest: p.split(path).contains('test'),
        ),
      );
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
