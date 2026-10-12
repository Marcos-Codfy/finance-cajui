import 'package:cajui/src/features/receipts/application/read_outcome.dart';
import 'package:cajui/src/features/receipts/application/shared_item.dart';
import 'package:cajui/src/features/receipts/infrastructure/native_receipt_reader.dart';
import 'package:cajui/src/features/statements/application/statement_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = MethodChannel('app.cajui/capture-test');

const _pdf = SharedFile(id: 'extrato', path: '/inbox/extrato.pdf', isPdf: true);

void _answer(Map<String, Object?> read) => TestDefaultBinaryMessengerBinding
    .instance
    .defaultBinaryMessenger
    .setMockMethodCallHandler(_channel, (call) async => read);

Future<ReadText> _read() async {
  const reader = NativeReceiptReader(
    progress: Stream.empty(),
    methods: _channel,
  );
  return await reader.read(_pdf) as ReadText;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final first = Uint8List.fromList([0xFF, 0xD8, 0xFF, 1]);
  final third = Uint8List.fromList([0xFF, 0xD8, 0xFF, 3]);

  group('ADR-030 · o leitor do aparelho entrega cada página', () {
    test('RN-1101 · o texto de cada página e o total real do PDF; o texto '
        'juntado continua, para o comprovante', () async {
      _answer({
        'text': 'página um\npágina dois',
        'pageTexts': ['página um', 'página dois'],
        'pageCount': 24,
        'images': [first],
        'imagePages': [1],
      });

      final read = await _read();

      expect(read.text, 'página um\npágina dois');
      expect(read.pageTexts, ['página um', 'página dois']);
      expect(read.pageCount, 24);
    });

    test('cada imagem fica com a sua página, mesmo quando a do meio não '
        'saiu', () async {
      _answer({
        'text': 'a\nb\nc',
        'pageTexts': ['a', 'b', 'c'],
        'pageCount': 3,
        'images': [first, third],
        'imagePages': [1, 3],
      });

      final pages = StatementPage.ofRead(await _read());

      expect(pages.map((page) => page.text), ['a', 'b', 'c']);
      expect(pages.map((page) => page.image), [first, null, third]);
    });

    test(
      'lado nativo antigo, sem as páginas: o texto é a página única',
      () async {
        _answer({'text': 'tudo junto', 'images': <Object?>[]});

        final read = await _read();

        expect(read.pageTexts, ['tudo junto']);
        expect(read.pageCount, isNull);
        expect(StatementPage.ofRead(read).single.text, 'tudo junto');
      },
    );
  });
}
