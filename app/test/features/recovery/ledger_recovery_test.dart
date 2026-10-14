import 'dart:convert';
import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_texts.g.dart';
import 'package:cajui/src/core/storage/event_store_opener_file.dart';
import 'package:cajui/src/features/recovery/presentation/ledger_recovery_app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persistence/persistence.dart';

/// Um registro com dois eventos, na pasta [ledger].
Future<void> _ledgerWithTwoEvents(Directory ledger) async {
  final store = await openEventStoreAt(ledger);
  for (final id in ['a', 'b']) {
    await store.append(id: id, type: 'teste', payload: {'id': id});
  }
  await store.close();
}

/// Troca o conteúdo cifrado da última linha, como duas cópias do app
/// gravando juntas deixam o arquivo.
void _breakLastLine(Directory ledger) {
  final file = LogReader.filesIn(ledger).single;
  final lines = const LineSplitter().convert(file.readAsStringSync());
  final last = jsonDecode(lines.last) as Map<String, Object?>;
  lines[lines.length - 1] = jsonEncode({...last, 'seq': 1});
  file.writeAsStringSync('${lines.join('\n')}\n');
}

Directory _temp() {
  final directory = Directory.systemTemp.createTempSync('cajui-recovery-');
  addTearDown(() => directory.deleteSync(recursive: true));
  return directory;
}

void main() {
  group('E-DATA-03 · o registro que não abre não deixa mais a tela preta', () {
    test('a cadeia que não confere vira E-DATA-03; o resto, E-APP-01', () {
      expect(
        LedgerRecoveryApp.codeOf(
          const LogIntegrityException(seq: 2, reason: 'seq repetido'),
        ),
        ErrorCode.data03,
      );
      expect(
        LedgerRecoveryApp.codeOf(const FileSystemException('sem acesso')),
        ErrorCode.app01,
      );
    });

    test('recomeçar guarda o registro quebrado de lado, sem apagar nada, e '
        'o app abre com um registro novo', () async {
      final root = _temp();
      final ledger = Directory('${root.path}/ledger');
      await _ledgerWithTwoEvents(ledger);
      _breakLastLine(ledger);
      await expectLater(
        openEventStoreAt(ledger),
        throwsA(isA<LogIntegrityException>()),
      );

      await setLedgerAsideAt(ledger);

      final aside = root.listSync().whereType<Directory>().singleWhere(
        (d) => d.path.contains('ledger-guardado-'),
      );
      expect(LogReader.filesIn(aside), hasLength(1));
      expect(File('${aside.path}/data.key').existsSync(), isTrue);
      final fresh = await openEventStoreAt(ledger);
      expect(fresh.events, isEmpty);
      await fresh.close();
    });

    testWidgets('a tela mostra o texto do catálogo, e o toque recomeça', (
      tester,
    ) async {
      var startedOver = 0;
      var retried = 0;
      await tester.pumpWidget(
        LedgerRecoveryApp(
          error: const LogIntegrityException(seq: 2, reason: 'seq repetido'),
          onRetry: () async => retried++,
          onStartOver: () async => startedOver++,
        ),
      );
      await tester.pump();

      expect(find.text(ErrorTexts.of(ErrorCode.data03).message), findsOne);
      expect(find.text('Código E-DATA-03'), findsOneWidget);
      await tester.tap(find.text('Recomeçar pelo servidor'));
      await tester.pump();

      expect(startedOver, 1);
      expect(retried, 0);
    });

    testWidgets('outra falha oferece tentar abrir de novo', (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        LedgerRecoveryApp(
          error: const FileSystemException('sem acesso'),
          onRetry: () async => retried++,
          onStartOver: () async {},
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Reabrir o app'));
      await tester.pump();

      expect(retried, 1);
    });
  });
}
