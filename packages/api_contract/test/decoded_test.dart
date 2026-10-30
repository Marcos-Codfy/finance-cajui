import 'package:api_contract/api_contract.dart';
import 'package:test/test.dart';

/// O pedido válido, com [key] trocado por [value].
Map<String, Object?> _with(String key, Object? value) => {
  ..._valid,
  key: value,
};

void main() {
  group('RNF-SEC-09 · pedido de fora vira valor, e não exceção', () {
    test('o que o decodificador entende volta como Understood', () {
      final read = Decoded.of(() => CreateEntryRequest.fromJson(_valid));

      expect(read, isA<Understood<CreateEntryRequest>>());
      expect((read as Understood<CreateEntryRequest>).value.id, 'e-0001');
    });

    test(
      'campo a mais é recusado com E-REQ-01, sem exceção para quem chama',
      () {
        final read = Decoded.of(
          () => CreateEntryRequest.fromJson(_with('admin', true)),
        );

        expect(read, isA<Refused<CreateEntryRequest>>());
        expect((read as Refused<CreateEntryRequest>).code, ErrorCode.req01);
      },
    );

    test('campo obrigatório de tipo errado é recusado com E-REQ-01', () {
      final read = Decoded.of(
        () => CreateEntryRequest.fromJson(_with('amountCents', '45,90')),
      );

      expect(read, isA<Refused<CreateEntryRequest>>());
    });

    test('a raiz que não é objeto é recusada, e não vira erro de tipo', () {
      final read = Decoded.of(
        () => CreateEntryRequest.fromJson(const <Object?>[1]),
      );

      expect(read, isA<Refused<CreateEntryRequest>>());
    });

    test('defeito do programa não é pedido malformado e continua subindo', () {
      expect(
        () => Decoded.of<int>(() => throw StateError('bug')),
        throwsStateError,
      );
    });
  });
}

const Map<String, Object?> _valid = {
  'id': 'e-0001',
  'description': 'Mercado do Bairro',
  'amountCents': 4590,
  'occurredOn': '2026-10-28',
  'categoryId': 'c-mercado',
  'paymentLines': [
    {'paymentMethodId': 'pm-pix', 'kind': 'pix', 'amountCents': 4590},
  ],
};
