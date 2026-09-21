// A medição que vigia o gatilho da ADR-004: quanto custa reabrir o registro
// com milhares de eventos. É script de medição, e imprime o resultado.
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:persistence/persistence.dart';

/// Grava milhares de eventos sintéticos e cronometra a reabertura do
/// registro, com e sem decifrar.
///
/// Uso: `dart run tool/load_benchmark.dart 50000`
///
/// A gravação do benchmark não faz `fsync` a cada evento — o que se mede aqui
/// é a **leitura** —, então os eventos são escritos de uma vez.
Future<void> main(List<String> arguments) async {
  final count = int.parse(arguments.isEmpty ? '50000' : arguments.first);
  final directory = Directory.systemTemp.createTempSync('cajui-benchmark-');
  final cipher = AesGcmRecordCipher(List.generate(32, (i) => i));
  try {
    final writing = Stopwatch()..start();
    await _writeAll(directory, cipher, count);
    print('gravar $count eventos: ${writing.elapsedMilliseconds} ms');

    final scanning = Stopwatch()..start();
    final scan = LogReader.scan(directory);
    print(
      'conferir a cadeia, sem a chave (${scan.lines.length} registros): '
      '${scanning.elapsedMilliseconds} ms',
    );

    final opening = Stopwatch()..start();
    final store = await FileEventStore.open(directory, cipher);
    print(
      'abrir tudo, decifrando (${store.events.length} eventos): '
      '${opening.elapsedMilliseconds} ms',
    );
    final size = LogReader.filesIn(directory).first.lengthSync();
    print('tamanho no disco: ${(size / 1024 / 1024).toStringAsFixed(1)} MiB');
  } finally {
    directory.deleteSync(recursive: true);
  }
}

/// Um evento do tamanho de um lançamento real, com pagamento dividido.
StoredEvent _syntheticEntry(int seq) => StoredEvent(
  seq: seq,
  id: 'event-$seq',
  type: 'entry.created',
  at: DateTime.utc(2026, 9, 12),
  schema: 1,
  payload: {
    'description': 'Mercado Boa Compra $seq',
    'amountCents': 18640 + seq,
    'categoryId': 'groceries',
    'paymentLines': [
      const {'paymentMethodId': 'voucher', 'amountCents': 3000},
      {'paymentMethodId': 'pix', 'amountCents': 15640 + seq},
    ],
  },
);

Future<void> _writeAll(
  Directory directory,
  RecordCipher cipher,
  int count,
) async {
  final buffer = StringBuffer();
  var previous = LogLine.genesis;
  for (var seq = 1; seq <= count; seq++) {
    final event = _syntheticEntry(seq);
    final box = await cipher.seal(
      event.toPlaintext().codeUnits,
      associated: LogLine.associatedData(cipher.version, seq, previous),
    );
    final line = LogLine(
      version: cipher.version,
      seq: seq,
      previousHash: previous,
      nonce: box.nonce,
      sealed: box.sealed,
    ).encode();
    buffer.writeln(line);
    previous = LogLine.hashOf(line);
  }
  LogReader.fileFor(directory, 2026).writeAsStringSync(buffer.toString());
}
