import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:persistence/persistence.dart';
import 'package:test/test.dart';

import 'support/temp_store.dart';

void main() {
  group('FileSnapshotStore', () {
    test('grava e lê de volta, cifrado no disco', () async {
      final directory = tempDirectory();
      final store = FileSnapshotStore(directory, testCipher());

      await store.write('month-2026-09', {
        'lastSeq': 42,
        'surplusCents': 55800,
      });

      expect(await store.read('month-2026-09'), {
        'lastSeq': 42,
        'surplusCents': 55800,
      });
      final onDisk = File(p.join(directory.path, 'month-2026-09.snapshot'))
          .readAsStringSync();
      expect(onDisk, isNot(contains('surplusCents')));
    });

    test(
      'ADR-004 regravar troca o arquivo inteiro, sem deixar temporário',
      () async {
        final directory = tempDirectory();
        final store = FileSnapshotStore(directory, testCipher());

        await store.write('s', {'lastSeq': 1});
        await store.write('s', {'lastSeq': 2});

        expect(await store.read('s'), {'lastSeq': 2});
        expect(directory.listSync().map((e) => p.basename(e.path)), [
          's.snapshot',
        ]);
      },
    );

    test(
      'resumo que não existe, ilegível ou adulterado volta como nulo',
      () async {
        final directory = tempDirectory();
        final store = FileSnapshotStore(directory, testCipher());
        await store.write('s', {'lastSeq': 1});

        expect(await store.read('outro'), isNull);

        File(p.join(directory.path, 's.snapshot')).writeAsStringSync('{lixo');
        expect(await store.read('s'), isNull);
      },
    );

    test('um resumo não abre no lugar de outro', () async {
      final directory = tempDirectory();
      final store = FileSnapshotStore(directory, testCipher());
      await store.write('a', {'lastSeq': 1});

      File(p.join(directory.path, 'a.snapshot'))
          .copySync(p.join(directory.path, 'b.snapshot'));

      expect(await store.read('b'), isNull);
    });
  });

  group('DataKey', () {
    test('gera 32 bytes, e cada chave é diferente da anterior', () {
      final first = DataKey.generate();

      expect(base64Decode(first), hasLength(32));
      expect(DataKey.generate(), isNot(first));
    });

    test('recusa chave de tamanho errado', () {
      final file = File(p.join(tempDirectory().path, 'key'))
        ..writeAsStringSync(base64Encode([1, 2, 3]));

      expect(() => DataKey.read(file.path), throwsFormatException);
    });

    test(
      'T-27 o ambiente guarda só o caminho da credencial, nunca a chave',
      () {
        expect(DataKey.systemdCredentialPath(const {}), isNull);
        expect(
          DataKey.systemdCredentialPath(const {
            'CREDENTIALS_DIRECTORY': '/run/c',
          }),
          endsWith('cajui-data-key'),
        );
      },
    );
  });

  group('dbtool', () {
    late Directory data;
    late String keyFile;
    late StringBuffer out;

    setUp(() async {
      data = tempDirectory();
      keyFile = p.join(tempDirectory().path, 'data.key');
      File(keyFile).writeAsStringSync(base64Encode(testKey));
      out = StringBuffer();
      await appendEntries(await openStore(data), 3);
    });

    Future<int> run(List<String> arguments) => DbTool(out).run(arguments);

    test('verify confere a cadeia sem a chave', () async {
      expect(await run(['verify', data.path]), 0);
      expect(out.toString(), contains('3 registros, cadeia conferida'));
    });

    test('verify aponta o registro exato quando a cadeia quebra', () async {
      final file = logFile(data);
      final lines = const LineSplitter().convert(file.readAsStringSync());
      file.writeAsStringSync('${[lines[0], lines[2]].join('\n')}\n');

      expect(await run(['verify', data.path]), 1);
      expect(out.toString(), contains('Registro 2 não confere'));
    });

    test('cat decifra e filtra por mês', () async {
      expect(await run(['cat', data.path, '--key-file', keyFile]), 0);
      expect(out.toString(), contains('"description":"Compra 2"'));

      out.clear();
      await run([
        'cat',
        data.path,
        '--key-file',
        keyFile,
        '--month',
        '2025-01',
      ]);
      expect(out.toString(), isEmpty);
    });

    test('export grava um JSON Lines legível', () async {
      final target = p.join(tempDirectory().path, 'export.jsonl');

      await run(['export', data.path, '--key-file', keyFile, '--out', target]);

      final exported = const LineSplitter().convert(
        File(target).readAsStringSync(),
      );
      expect(exported, hasLength(3));
      expect(jsonDecode(exported.first), containsPair('seq', 1));
    });

    test('keygen nunca sobrescreve uma chave existente', () async {
      expect(await run(['keygen', keyFile]), 64);
      expect(base64Decode(File(keyFile).readAsStringSync()), testKey);
    });

    test('comando desconhecido devolve o uso', () async {
      expect(await run(['apagar', data.path]), 64);
      expect(out.toString(), contains('uso: dbtool'));
    });
  });
}
