import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:persistence/src/log_integrity_exception.dart';
import 'package:persistence/src/log_line.dart';
import 'package:persistence/src/log_scan.dart';

/// Percorre os arquivos do registro e confere a cadeia — **sem a chave**.
///
/// É a mesma leitura que o servidor faz ao subir e que o `dbtool verify` faz
/// numa cópia de backup. Conferir integridade não depende de segredo: basta
/// cada linha guardar o hash da anterior.
abstract final class LogReader {
  static final _fileName = RegExp(r'^events-(\d{4})\.jsonl$');

  /// O arquivo do ano [year] dentro de [directory].
  static File fileFor(Directory directory, int year) =>
      File(p.join(directory.path, 'events-$year.jsonl'));

  /// Os arquivos do registro em [directory], do ano mais antigo ao mais novo.
  static List<File> filesIn(Directory directory) {
    if (!directory.existsSync()) return const [];
    final files = directory
        .listSync()
        .whereType<File>()
        .where((file) => _fileName.hasMatch(p.basename(file.path)))
        .toList();
    return files..sort((a, b) => a.path.compareTo(b.path));
  }

  /// Lê tudo e confere a cadeia. Lança [LogIntegrityException] no primeiro
  /// registro que não confere.
  ///
  /// Uma única coisa é tolerada: a **última** linha do **último** arquivo
  /// estar pela metade. É o que sobra quando o processo morre entre o
  /// `append` e o `fsync`; o evento não chegou a ser confirmado a ninguém, e
  /// é descartado.
  static LogScan scan(Directory directory) {
    final files = filesIn(directory);
    final lines = <LogLine>[];
    var lastHash = LogLine.genesis;
    for (final file in files) {
      final bytes = file.readAsBytesSync();
      final complete = bytes.lastIndexOf(0x0A) + 1;
      final torn = complete < bytes.length;
      if (torn && !identical(file, files.last)) {
        throw LogIntegrityException(
          seq: lines.length + 1,
          reason: 'linha incompleta fora do fim do registro',
        );
      }
      lastHash = _appendChecked(lines, _linesOf(bytes, complete), lastHash);
      if (torn) {
        return LogScan(
          lines: lines,
          lastHash: lastHash,
          tornFile: file,
          tornValidLength: complete,
        );
      }
    }
    return LogScan(lines: lines, lastHash: lastHash);
  }

  /// Acrescenta a [lines] as linhas de [texts], conferindo cada uma contra a
  /// anterior, e devolve o hash da última.
  static String _appendChecked(
    List<LogLine> lines,
    Iterable<String> texts,
    String previousHash,
  ) {
    var hash = previousHash;
    for (final text in texts) {
      lines.add(_checked(text, lines.length + 1, hash));
      hash = LogLine.hashOf(text);
    }
    return hash;
  }

  static Iterable<String> _linesOf(List<int> bytes, int complete) =>
      const LineSplitter()
          .convert(utf8.decode(bytes.sublist(0, complete)))
          .where((line) => line.isNotEmpty);

  /// Confere se [text] é a linha [expectedSeq] e se aponta para a anterior.
  static LogLine _checked(String text, int expectedSeq, String previousHash) {
    final LogLine line;
    try {
      line = LogLine.parse(text);
    } on Object {
      throw LogIntegrityException(seq: expectedSeq, reason: 'linha ilegível');
    }
    if (line.seq != expectedSeq) {
      throw LogIntegrityException(
        seq: expectedSeq,
        reason: 'esperava o registro $expectedSeq e achou o ${line.seq}',
      );
    }
    if (line.previousHash != previousHash) {
      throw LogIntegrityException(
        seq: expectedSeq,
        reason: 'o elo com o registro anterior não bate',
      );
    }
    return line;
  }
}
