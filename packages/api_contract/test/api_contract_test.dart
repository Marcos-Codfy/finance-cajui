import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:test/test.dart';

/// As linhas de código do catálogo em Markdown: código e status HTTP.
Map<String, int?> _catalog() {
  final row = RegExp(r'^\| `(E-[A-Z]+-\d\d)`[^|]*\|[^|]+\|([^|]+)\|');
  final text = File('../../docs/spec/error-catalog.md').readAsStringSync();
  return {
    for (final match in text.split('\n').map(row.firstMatch).nonNulls)
      match.group(1)!: int.tryParse(
        RegExp(r'api (\d{3})').firstMatch(match.group(2)!)?.group(1) ?? '',
      ),
  };
}

Map<String, Object?> _entryJson() => {
  'id': 'e1',
  'description': 'Mercado Boa Compra',
  'amountCents': 8600,
  'occurredOn': '2026-09-12',
  'categoryId': 'groceries',
  'paymentLines': [
    {'paymentMethodId': 'voucher', 'kind': 'mealVoucher', 'amountCents': 3000},
    {'paymentMethodId': 'pix', 'kind': 'pix', 'amountCents': 5600},
  ],
};

void main() {
  group('ErrorCode', () {
    test('ADR-015 o enum e o catálogo em Markdown dizem a mesma coisa', () {
      final catalog = _catalog();

      expect(catalog, hasLength(45));
      expect({for (final code in ErrorCode.values) code.code}, catalog.keys);
      for (final code in ErrorCode.values) {
        expect(code.httpStatus, catalog[code.code], reason: code.code);
      }
    });

    test('RNF-SEC-18 os erros de autenticação são da classe segurança', () {
      final auth = ErrorCode.values.where((c) => c.code.startsWith('E-AUTH'));

      expect(auth.map((c) => c.errorClass).toSet(), {ErrorClass.security});
    });
  });

  group('ApiError', () {
    test('vai e volta pelo JSON, com os valores do texto', () {
      const error = ApiError(
        code: ErrorCode.voucher01,
        ref: '7f3a9c',
        detail: {'balanceCents': 2260, 'requestedCents': 3840},
      );

      final parsed = ApiError.fromJson(error.toJson());

      expect(parsed.code, ErrorCode.voucher01);
      expect(parsed.ref, '7f3a9c');
      expect(parsed.detail['balanceCents'], 2260);
      expect(error.toJson()['error'], containsPair('class', 'regra'));
    });

    test('código desconhecido ou corpo estranho vira E-SRV-01, com o ref', () {
      final unknown = ApiError.fromJson(const {
        'error': {'code': 'E-NOVO-99', 'ref': 'abc'},
      });

      expect(unknown.code, ErrorCode.srv01);
      expect(unknown.ref, 'abc');
      expect(ApiError.fromJson(const {'oops': 1}).code, ErrorCode.srv01);
    });
  });

  group('CreateEntryRequest', () {
    test('lê um pedido bem formado e o devolve igual', () {
      final request = CreateEntryRequest.fromJson(_entryJson());

      expect(request.paymentLines, hasLength(2));
      expect(request.isExceptional, isFalse);
      expect(request.toJson()['amountCents'], 8600);
    });

    test('RNF-SEC-09 campo a mais é recusado', () {
      final json = _entryJson()..['isAdmin'] = true;

      expect(() => CreateEntryRequest.fromJson(json), throwsFormatException);
    });

    test(
      'RNF-SEC-09 tipo errado, campo faltando e texto enorme são recusados',
      () {
        final wrongType = _entryJson()..['amountCents'] = '8600';
        final missing = _entryJson()..remove('categoryId');
        final huge = _entryJson()..['description'] = 'x' * 201;
        final noLines = _entryJson()..['paymentLines'] = <Object?>[];

        for (final json in [wrongType, missing, huge, noLines]) {
          expect(
            () => CreateEntryRequest.fromJson(json),
            throwsFormatException,
          );
        }
      },
    );

    test('o que não é objeto é recusado', () {
      expect(() => CreateEntryRequest.fromJson('texto'), throwsFormatException);
    });
  });
}
