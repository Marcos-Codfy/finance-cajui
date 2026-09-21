import 'dart:convert';
import 'dart:io';

import 'package:persistence/persistence.dart';
import 'package:test/test.dart';

import 'support/temp_store.dart';

/// Reescreve o arquivo do registro com as linhas transformadas por [change].
void _rewrite(Directory directory, List<String> Function(List<String>) change) {
  final file = logFile(directory);
  final lines = const LineSplitter().convert(file.readAsStringSync());
  file.writeAsStringSync('${change(lines).join('\n')}\n');
}

Matcher _brokenAt(int seq) =>
    throwsA(isA<LogIntegrityException>().having((e) => e.seq, 'seq', seq));

void main() {
  group('gravar e reabrir', () {
    test(
      'o que foi gravado volta igual, na ordem, depois de reabrir',
      () async {
        final directory = tempDirectory();
        await appendEntries(await openStore(directory), 3);

        final reopened = await openStore(directory);

        expect(reopened.events.map((e) => e.seq), [1, 2, 3]);
        expect(reopened.events.last.payload['amountCents'], 1003);
        expect(reopened.events.last.at, DateTime.utc(2026, 9, 12, 15, 30));
      },
    );

    test(
      'ADR-004 um arquivo por ano, com a cadeia atravessando a virada',
      () async {
        final directory = tempDirectory();
        var year = 2026;
        final store = await FileEventStore.open(
          directory,
          testCipher(),
          now: () => DateTime.utc(year, 12, 31),
        );
        await appendEntries(store, 2);
        year = 2027;
        await store.append(id: 'novo-ano', type: 'entry.created', payload: {});

        expect(LogReader.filesIn(directory), hasLength(2));
        expect((await openStore(directory)).events, hasLength(3));
      },
    );

    test('T-33 nada legível vai para o disco', () async {
      final directory = tempDirectory();
      await appendEntries(await openStore(directory), 1);

      final onDisk = logFile(directory).readAsStringSync();

      expect(onDisk, isNot(contains('Compra')));
      expect(onDisk, isNot(contains('amountCents')));
      expect(onDisk, contains('"seq":1'));
    });

    test(
      'ADR-005 a mesma mensagem cifrada duas vezes dá linhas diferentes',
      () async {
        final cipher = testCipher();

        final first = await cipher.seal([1, 2, 3], associated: [9]);
        final second = await cipher.seal([1, 2, 3], associated: [9]);

        expect(first.nonce, isNot(second.nonce));
        expect(first.sealed, isNot(second.sealed));
      },
    );

    test('ADR-012 o mesmo id gravado duas vezes vira um evento só', () async {
      final directory = tempDirectory();
      final store = await openStore(directory);

      final first = await store.append(id: 'x', type: 't', payload: {'n': 1});
      final again = await store.append(id: 'x', type: 't', payload: {'n': 2});

      expect(again.seq, first.seq);
      expect(again.payload['n'], 1);
      expect((await openStore(directory)).events, hasLength(1));
    });

    test('gravações simultâneas entram em fila e não se misturam', () async {
      final directory = tempDirectory();
      final store = await openStore(directory);

      await Future.wait([
        for (var i = 0; i < 20; i++)
          store.append(id: 'c$i', type: 't', payload: {'i': i}),
      ]);

      final reopened = await openStore(directory);
      expect(
        reopened.events.map((e) => e.seq),
        List.generate(20, (i) => i + 1),
      );
    });
  });

  group('T-31 adulteração do registro', () {
    late Directory directory;

    setUp(() async {
      directory = tempDirectory();
      await appendEntries(await openStore(directory), 4);
    });

    test('linha removida é detectada, com o ponto exato', () {
      _rewrite(directory, (lines) => lines..removeAt(1));

      expect(() => LogReader.scan(directory), _brokenAt(2));
    });

    test('linhas reordenadas são detectadas', () {
      _rewrite(directory, (lines) => [lines[0], lines[2], lines[1], lines[3]]);

      expect(() => LogReader.scan(directory), _brokenAt(2));
    });

    test(
      'conteúdo alterado é detectado ao abrir, mesmo com a cadeia refeita',
      () async {
        // Quem tem acesso ao disco pode recalcular os hashes; o que não pode é
        // produzir um conteúdo cifrado válido sem a chave.
        _rewrite(directory, (lines) {
          final forged = jsonDecode(lines[3]) as Map<String, Object?>;
          forged['c'] = (jsonDecode(lines[2]) as Map<String, Object?>)['c'];
          return [...lines.take(3), jsonEncode(forged)];
        });

        await expectLater(openStore(directory), _brokenAt(4));
      },
    );

    test('registro truncado no meio da cadeia não passa despercebido', () {
      // Cortar as últimas linhas inteiras deixa uma cadeia válida, porém mais
      // curta: só o resumo, que guarda o último `seq`, denuncia a falta.
      _rewrite(directory, (lines) => lines.take(2).toList());

      expect(LogReader.scan(directory).lines, hasLength(2));
    });

    test('chave errada não abre nada', () async {
      final other = AesGcmRecordCipher(List.filled(32, 7));

      await expectLater(openStore(directory, cipher: other), _brokenAt(1));
    });
  });

  group('T-32 queda no meio de uma escrita', () {
    test(
      'a linha pela metade é descartada, e a cadeia continua íntegra',
      () async {
        final directory = tempDirectory();
        await appendEntries(await openStore(directory), 2);
        logFile(directory).writeAsStringSync(
          '{"v":1,"seq":3,"prev":"abc","n":"AAA',
          mode: FileMode.append,
        );

        final reopened = await openStore(directory);
        await reopened.append(id: 'depois', type: 't', payload: {});

        expect(reopened.events.map((e) => e.seq), [1, 2, 3]);
        expect((await openStore(directory)).events.last.id, 'depois');
      },
    );
  });
}
