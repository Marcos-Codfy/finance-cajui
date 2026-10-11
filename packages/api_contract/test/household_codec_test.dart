import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

Map<String, Object?> _fact(Map<String, Object?> payload) => {
  'id': 'household-1',
  'type': DeviceFact.householdNamed,
  'payload': payload,
};

void main() {
  final at = DateTime.utc(2026, 10, 11, 12);

  group('RN-1070 · os nomes da casa viajam como fato do aparelho', () {
    test('a lista vai e volta inteira, com o carimbo', () {
      final names = HouseholdNames(
        names: const ['Marcos Vinícius Muniz Arruda', 'Beatriz Souza Lima'],
        definedAt: at,
      );

      final fact = DeviceFact.read(_fact(HouseholdCodec.encode(names)));
      final back = HouseholdCodec.decode(fact.payload);

      expect(back.names, names.names);
      expect(back.definedAt, at);
    });

    test('T-05 · nome sem sobrenome, nome longo demais, lista grande demais e '
        'lista sem carimbo são recusados', () {
      final stamp = at.toIso8601String();
      final recusados = [
        {
          'names': ['Marcos'],
          'definedAt': stamp,
        },
        {
          'names': ['${'a' * 50} ${'b' * 50}'],
          'definedAt': stamp,
        },
        {
          'names': [for (var i = 0; i < 7; i++) 'Pessoa Lima'],
          'definedAt': stamp,
        },
        {
          'names': ['Marcos Arruda'],
        },
        {'names': 'Marcos Arruda', 'definedAt': stamp},
      ];

      for (final payload in recusados) {
        expect(() => DeviceFact.read(_fact(payload)), throwsFormatException);
      }
    });

    test('o conteúdo volta normalizado: campo a mais não é guardado', () {
      final fact = DeviceFact.read(
        _fact({
          'names': [' Marcos Arruda '],
          'definedAt': at.toIso8601String(),
          'cpf': '000',
        }),
      );

      expect(fact.payload.keys, unorderedEquals(['names', 'definedAt']));
      expect(fact.payload['names'], ['Marcos Arruda']);
    });
  });
}
