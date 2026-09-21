import 'dart:io';

import 'package:meta/meta.dart';
import 'package:persistence/src/log_line.dart';

/// O resultado de percorrer o registro no disco, com a cadeia já conferida.
@immutable
final class LogScan {
  /// Cria o resultado.
  const new({
    required this.lines,
    required this.lastHash,
    this.tornFile,
    this.tornValidLength,
  });

  /// As linhas íntegras, na ordem.
  final List<LogLine> lines;

  /// O hash da última linha íntegra: o `prev` da próxima a ser gravada.
  final String lastHash;

  /// O arquivo que terminava com uma linha pela metade — o rastro de um
  /// processo que morreu no meio de uma escrita —, se houver.
  final File? tornFile;

  /// Até que byte o [tornFile] é válido. O que vem depois é descartado.
  final int? tornValidLength;

  /// A posição da próxima linha a gravar.
  int get nextSeq => lines.length + 1;
}
