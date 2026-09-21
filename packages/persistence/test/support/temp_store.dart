import 'dart:io';

import 'package:persistence/persistence.dart';
import 'package:test/test.dart';

/// Uma chave fixa: os testes precisam ser reproduzíveis.
final List<int> testKey = List.generate(32, (index) => index);

/// A cifra dos testes.
RecordCipher testCipher() => AesGcmRecordCipher(testKey);

/// Uma pasta temporária, apagada no fim do teste.
Directory tempDirectory() {
  final directory = Directory.systemTemp.createTempSync('cajui-persistence-');
  addTearDown(() => directory.deleteSync(recursive: true));
  return directory;
}

/// Abre o registro em [directory] com um relógio parado em setembro de 2026.
Future<FileEventStore> openStore(Directory directory, {RecordCipher? cipher}) =>
    FileEventStore.open(
      directory,
      cipher ?? testCipher(),
      now: () => DateTime.utc(2026, 9, 12, 15, 30),
    );

/// Grava [count] eventos de lançamento, com valores distintos.
Future<void> appendEntries(EventStore store, int count) async {
  for (var i = 1; i <= count; i++) {
    await store.append(
      id: 'entry-$i',
      type: 'entry.created',
      payload: {'amountCents': 1000 + i, 'description': 'Compra $i'},
    );
  }
}

/// O único arquivo do registro em [directory].
File logFile(Directory directory) => LogReader.filesIn(directory).single;
