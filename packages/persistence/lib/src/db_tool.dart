import 'dart:convert';
import 'dart:io';

import 'package:persistence/src/aes_gcm_record_cipher.dart';
import 'package:persistence/src/data_key.dart';
import 'package:persistence/src/file_event_store.dart';
import 'package:persistence/src/log_integrity_exception.dart';
import 'package:persistence/src/log_reader.dart';
import 'package:persistence/src/stored_event.dart';

/// O `dbtool`: a resposta ao pedido de "ler os dados por SSH" quando os dados
/// estão cifrados (ADR-005). Só lê; quem grava é o servidor.
///
/// ```text
/// dbtool keygen <arquivo-da-chave>
/// dbtool verify <pasta> [--key-file <arquivo>]
/// dbtool cat    <pasta> --key-file <arquivo> [--month 2026-09]
/// dbtool export <pasta> --key-file <arquivo> --out <arquivo.jsonl>
/// ```
final class DbTool {
  /// Cria a ferramenta escrevendo em [out].
  new(this.out);

  /// Para onde vai o que a ferramenta imprime.
  final StringSink out;

  /// Executa [arguments] e devolve o código de saída: 0 quando deu certo, 1
  /// quando o registro não confere, 64 quando o comando está errado.
  Future<int> run(List<String> arguments) async {
    if (arguments.length < 2) return _usage();
    final target = arguments[1];
    final options = _options(arguments.skip(2).toList());
    try {
      return switch (arguments.first) {
        'keygen' => _keygen(target),
        'verify' => await _verify(target, options['--key-file']),
        'cat' => await _cat(target, options),
        'export' => await _export(target, options),
        _ => _usage(),
      };
    } on LogIntegrityException catch (error) {
      out.writeln('FALHA: $error');
      return 1;
    }
  }

  int _usage() {
    out.writeln('uso: dbtool keygen|verify|cat|export <alvo> [opções]');
    return 64;
  }

  Map<String, String> _options(List<String> rest) => {
    for (var i = 0; i + 1 < rest.length; i += 2) rest[i]: rest[i + 1],
  };

  /// Nunca sobrescreve: perder a chave é perder o registro.
  int _keygen(String path) {
    final file = File(path);
    if (file.existsSync()) {
      out.writeln('Já existe um arquivo em $path. Nada foi alterado.');
      return 64;
    }
    file.writeAsStringSync('${DataKey.generate()}\n', flush: true);
    out.writeln('Chave gravada em $path. Guarde uma cópia fora do servidor.');
    return 0;
  }

  /// Sem chave, confere só a cadeia — o bastante para validar um backup em
  /// qualquer máquina. Com chave, abre também cada registro.
  Future<int> _verify(String directory, String? keyFile) async {
    final scan = LogReader.scan(Directory(directory));
    if (keyFile != null) await _open(directory, keyFile);
    final depth = keyFile == null ? 'cadeia conferida' : 'cadeia e conteúdo';
    out.writeln('OK: ${scan.lines.length} registros, $depth.');
    if (scan.tornFile != null) {
      out.writeln('Aviso: a última linha está incompleta e será descartada.');
    }
    return 0;
  }

  Future<FileEventStore> _open(String directory, String keyFile) =>
      FileEventStore.open(
        Directory(directory),
        AesGcmRecordCipher(DataKey.read(keyFile)),
      );

  Future<int> _cat(String directory, Map<String, String> options) async {
    final keyFile = options['--key-file'];
    if (keyFile == null) return _usage();
    final month = options['--month'];
    final store = await _open(directory, keyFile);
    store.events
        .where((e) => month == null || _monthOf(e) == month)
        .map(_readable)
        .forEach(out.writeln);
    return 0;
  }

  Future<int> _export(String directory, Map<String, String> options) async {
    final keyFile = options['--key-file'];
    final target = options['--out'];
    if (keyFile == null || target == null) return _usage();
    final store = await _open(directory, keyFile);
    File(target).writeAsStringSync(
      store.events.map((e) => '${_readable(e)}\n').join(),
      flush: true,
    );
    out.writeln('${store.events.length} registros exportados para $target.');
    return 0;
  }

  String _monthOf(StoredEvent event) =>
      event.at.toUtc().toIso8601String().substring(0, 7);

  String _readable(StoredEvent event) => jsonEncode({
    'seq': event.seq,
    ...jsonDecode(event.toPlaintext()) as Map<String, Object?>,
  });
}
