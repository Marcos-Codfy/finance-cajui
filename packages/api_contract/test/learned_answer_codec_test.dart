import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

Map<String, Object?> _fact(String type, Map<String, Object?> payload) => {
  'id': 'fato-1',
  'type': type,
  'payload': payload,
};

void main() {
  final at = DateTime.utc(2026, 10, 11, 12);

  group('RN-1116 · a resposta lembrada viaja como fato do aparelho', () {
    test('a resposta vai e volta inteira: chave, categoria, tipo, pessoa e '
        'carimbo', () {
      final answer = LearnedAnswer(
        key: 'pessoa:joao p silva',
        definedAt: at,
        categoryId: 'services',
        treatment: LineTreatment.household,
        aboutPerson: true,
      );

      final fact = DeviceFact.read(
        _fact(DeviceFact.merchantLearned, LearnedAnswerCodec.encode(answer)),
      );
      final back = LearnedAnswerCodec.decode(fact.payload);

      expect(back.key, answer.key);
      expect(back.categoryId, 'services');
      expect(back.treatment, LineTreatment.household);
      expect(back.aboutPerson, isTrue);
      expect(back.definedAt, at);
    });

    test('a resposta esquecida também viaja: sem categoria e sem tipo', () {
      final forgotten = LearnedAnswer(key: 'padaria boa vista', definedAt: at);

      final fact = DeviceFact.read(
        _fact(DeviceFact.merchantLearned, LearnedAnswerCodec.encode(forgotten)),
      );

      expect(LearnedAnswerCodec.decode(fact.payload).isForgotten, isTrue);
    });

    test('T-05 · chave vazia ou longa demais, tipo inventado e carimbo sem '
        'fuso são recusados', () {
      final stamp = at.toIso8601String();
      final recusados = [
        {'key': '', 'definedAt': stamp},
        {'key': 'a' * 81, 'definedAt': stamp},
        {'key': 'padaria', 'treatment': 'presente', 'definedAt': stamp},
        {'key': 'padaria', 'definedAt': '2026-10-11T12:00:00'},
        {'key': 'padaria', 'aboutPerson': 'sim', 'definedAt': stamp},
        {'key': 'padaria', 'categoryId': 7, 'definedAt': stamp},
      ];

      for (final payload in recusados) {
        expect(
          () => DeviceFact.read(_fact(DeviceFact.merchantLearned, payload)),
          throwsFormatException,
          reason: '$payload',
        );
      }
    });

    test('campo a mais não é guardado', () {
      final fact = DeviceFact.read(
        _fact(DeviceFact.merchantLearned, {
          'key': 'padaria boa vista',
          'categoryId': 'bakery',
          'definedAt': at.toIso8601String(),
          'texto': 'PADARIA BOA VISTA 12,00',
        }),
      );

      expect(fact.payload.containsKey('texto'), isFalse);
      expect(fact.payload['aboutPerson'], isFalse);
    });
  });

  group('RN-1120 · o recebimento desfeito viaja como fato do aparelho', () {
    test('vai e volta com o recebimento e o dia', () {
      final fact = DeviceFact.read(
        _fact(
          DeviceFact.incomeCancelled,
          IncomeCancellationCodec.encode((
            receiptId: 'salario-outubro',
            on: LocalDate(2026, 10, 11),
          )),
        ),
      );
      final back = IncomeCancellationCodec.decode(fact.payload);

      expect(back.receiptId, 'salario-outubro');
      expect(back.on, LocalDate(2026, 10, 11));
    });

    test('T-05 · sem recebimento, ou com dia impossível, é recusado', () {
      final recusados = [
        {'on': '2026-10-11'},
        {'receiptId': '', 'on': '2026-10-11'},
        {'receiptId': 'r1', 'on': '2026-02-30'},
        {'receiptId': 'r1'},
      ];

      for (final payload in recusados) {
        expect(
          () => DeviceFact.read(_fact(DeviceFact.incomeCancelled, payload)),
          throwsFormatException,
          reason: '$payload',
        );
      }
    });
  });
}
