import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/assistant/application/speech_input.dart';
import 'package:cajui/src/features/assistant/infrastructure/native_speech_input.dart';
import 'package:cajui/src/features/assistant/infrastructure/no_speech_input.dart';
import 'package:cajui/src/features/receipts/application/read_outcome.dart';
import 'package:cajui/src/features/receipts/application/receipt_reader.dart';
import 'package:cajui/src/features/receipts/application/shared_item.dart';
import 'package:cajui/src/features/receipts/infrastructure/native_receipt_reader.dart';
import 'package:cajui/src/features/receipts/infrastructure/no_receipt_reader.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contrato das portas que têm uma versão de verdade e uma versão "sem nada".
///
/// Substituir uma implementação por outra não pode surpreender quem usa a
/// porta (o L do SOLID). Em vez de testar cada classe com a sua própria
/// expectativa, a **mesma** suíte roda contra todas: se uma delas passar a
/// lançar exceção onde as outras devolvem valor, é aqui que aparece.

const _channel = MethodChannel('test/port-contract');

/// Faz o lado nativo simulado responder com [handler]; `null` é o aparelho
/// sem o módulo (`MissingPluginException`).
void _platform(Future<Object?> Function(MethodCall call)? handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

/// O que acontece do outro lado do canal.
final _platforms = <String, Future<Object?> Function(MethodCall)?>{
  'sem o módulo nativo': null,
  'com erro do lado nativo': (call) async =>
      throw PlatformException(code: 'E-CAPT-01'),
  'com erro de código desconhecido': (call) async =>
      throw PlatformException(code: 'qualquer-coisa'),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => _platform(null));

  group('ADR-018 · SpeechInput: todo reconhecedor degrada em silêncio', () {
    final speech = <String, SpeechInput Function()>{
      'NoSpeechInput': NoSpeechInput.new,
      'NativeSpeechInput': () => const NativeSpeechInput(channel: _channel),
    };

    for (final MapEntry(key: name, value: make) in speech.entries) {
      for (final MapEntry(key: scenario, value: handler)
          in _platforms.entries) {
        test(
          '$name $scenario: não lança, diz que não ouve e devolve nada',
          () async {
            _platform(handler);
            final input = make();

            expect(await input.isAvailable(), isFalse);
            expect(await input.listen(), isNull);
          },
        );
      }
    }

    test('NativeSpeechInput repassa o que o aparelho ouviu', () async {
      _platform(
        (call) async => call.method == 'listen' ? 'quanto sobrou' : true,
      );
      const input = NativeSpeechInput(channel: _channel);

      expect(await input.isAvailable(), isTrue);
      expect(await input.listen(), 'quanto sobrou');
    });
  });

  group(
    'ADR-007 · ReceiptReader: leitura que falha é valor, e não exceção',
    () {
      const file = SharedFile(id: 's-1', path: 'sem-arquivo.jpg', isPdf: false);
      final readers = <String, ReceiptReader Function()>{
        'NoReceiptReader': NoReceiptReader.new,
        'NativeReceiptReader': () => const NativeReceiptReader(
          progress: Stream.empty(),
          methods: _channel,
        ),
      };

      for (final MapEntry(key: name, value: make) in readers.entries) {
        for (final MapEntry(key: scenario, value: handler)
            in _platforms.entries) {
          test(
            '$name $scenario: devolve ReadFailed com código do catálogo',
            () async {
              _platform(handler);
              final outcome = await make().read(file);

              // O ramo "sem módulo" do leitor nativo também falha de forma
              // tipada; só não pode ser uma exceção nem um texto inventado.
              expect(outcome, isA<ReadFailed>());
              expect(ErrorCode.values, contains((outcome as ReadFailed).code));
            },
          );
        }
      }

      test(
        'NativeReceiptReader entende o código do catálogo que o nativo manda',
        () async {
          _platform((call) async => throw PlatformException(code: 'E-CAPT-04'));
          const reader = NativeReceiptReader(
            progress: Stream.empty(),
            methods: _channel,
          );

          final outcome = await reader.read(file);

          expect((outcome as ReadFailed).code, ErrorCode.capt04);
        },
      );
    },
  );
}
