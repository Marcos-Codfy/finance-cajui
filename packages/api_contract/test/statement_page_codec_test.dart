import 'dart:convert';
import 'dart:typed_data';

import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

/// Ida e volta pela rede: o que o servidor recebe é JSON de verdade.
Object? _wire(Map<String, Object?> json) => jsonDecode(jsonEncode(json));

StatementMovement _movement({int line = 2, int day = 5, int cents = 15000}) =>
    StatementMovement(
      sourceLine: line,
      day: day,
      month: 10,
      description: 'Padaria Boa Vista',
      amount: Money.fromCents(cents),
      categoryId: 'bakery',
      confidence: Confidence.high,
      paymentKind: PaymentMethodKind.debit,
    );

void main() {
  group('ADR-030 · o pedido de leitura de uma página', () {
    final request = StatementPageRequest(
      lines: const ['EXTRATO OUTUBRO 2026', '05/10 PIX ENVIADO [NOME] 150,00'],
      page: 3,
      pageCount: 7,
      image: Uint8List.fromList([0xFF, 0xD8, 0xFF, 1]),
      period: const BudgetMonth(2026, 10),
      examples: const {'padaria boa vista': 'bakery'},
    );

    test('vai e volta inteiro', () {
      final back = StatementPageRequest.fromJson(_wire(request.toJson()));

      expect(back.lines, request.lines);
      expect(back.page, 3);
      expect(back.pageCount, 7);
      expect(back.image, request.image);
      expect(back.period, const BudgetMonth(2026, 10));
      expect(back.examples, {'padaria boa vista': 'bakery'});
    });

    test('RN-1106 · linha com quebra dentro é pedido malformado: a '
        'numeração não pode mentir', () {
      final json = _wire(request.toJson())! as Map<String, Object?>;

      expect(
        () => StatementPageRequest.fromJson({
          ...json,
          'lines': const ['uma\nduas'],
        }),
        throwsFormatException,
      );
    });

    test('página fora do extrato, campo a mais ou nada a ler: malformado', () {
      final json = _wire(request.toJson())! as Map<String, Object?>;

      for (final broken in [
        {...json, 'page': 8},
        {...json, 'extra': 1},
        {'page': 1, 'pageCount': 1},
      ]) {
        expect(
          () => StatementPageRequest.fromJson(broken),
          throwsFormatException,
          reason: '$broken',
        );
      }
    });

    test('exemplo a mais não recusa: valem os vinte últimos', () {
      final many = StatementPageRequest(
        lines: const ['linha'],
        page: 1,
        pageCount: 1,
        examples: {for (var i = 0; i < 25; i++) 'loja $i': 'groceries'},
      );

      final back = StatementPageRequest.fromJson(_wire(many.toJson()));

      expect(back.examples, hasLength(20));
      expect(back.examples.keys.first, 'loja 5');
    });
  });

  group('ADR-030 · a resposta de uma página', () {
    bool knows(String id) => id == 'bakery';

    test('vai e volta, com a linha de origem e a confiança', () {
      final reply = StatementPageReply(
        movements: [_movement()],
        period: const BudgetMonth(2026, 10),
      );

      final back = StatementPageReply.fromJson(
        _wire(reply.toJson())! as Map<String, Object?>,
        knowsCategory: knows,
      );

      final movement = back.movements.single;
      expect(movement.sourceLine, 2);
      expect(movement.amount, const Money.fromCents(15000));
      expect(movement.confidence, Confidence.high);
      expect(movement.paymentKind, PaymentMethodKind.debit);
      expect(back.period, const BudgetMonth(2026, 10));
      expect(back.partial, isFalse);
    });

    test('movimentação que não se lê cai fora sozinha; categoria que o '
        'aparelho não tem fica de fora', () {
      final json = {
        'movements': [
          _movement().toJson(),
          {..._movement().toJson(), 'amountCents': 0},
          {..._movement().toJson(), 'month': 13},
          'texto solto',
        ],
        'period': 'outubro',
      };

      final back = StatementPageReply.fromJson(
        json,
        knowsCategory: (_) => false,
      );

      expect(back.movements, hasLength(1));
      expect(back.movements.single.categoryId, isNull);
      expect(back.period, isNull);
    });

    test('RN-1104 · mais de 60 movimentações: a página vem marcada como '
        'lida em parte, nunca cortada em silêncio', () {
      final json = {
        'movements': [
          for (var i = 1; i <= 61; i++) _movement(line: i).toJson(),
        ],
      };

      final back = StatementPageReply.fromJson(json, knowsCategory: knows);

      expect(back.movements, hasLength(60));
      expect(back.partial, isTrue);
    });
  });

  group('RN-1105 · a data ganha o ano do período do extrato', () {
    test('"05/10" num extrato de outubro/2026 é 05/10/2026, com a página '
        'e a linha', () {
      final line = _movement().lineOn(
        page: 3,
        period: const BudgetMonth(2026, 10),
        today: LocalDate(2026, 10, 11),
      )!;

      expect(line.occurredOn, LocalDate(2026, 10, 5));
      expect(line.page, 3);
      expect(line.sourceLine, 2);
    });

    test('"28/12" num extrato de janeiro/2027 é de 2026; data depois de '
        'hoje cai', () {
      const december = StatementMovement(
        day: 28,
        month: 12,
        description: 'Mercado',
        amount: Money.fromCents(100),
      );

      final line = december.lineOn(
        page: 1,
        period: const BudgetMonth(2027, 1),
        today: LocalDate(2027, 1, 10),
      );
      final future = _movement(day: 20).lineOn(
        page: 1,
        period: const BudgetMonth(2026, 10),
        today: LocalDate(2026, 10, 11),
      );

      expect(line!.occurredOn, LocalDate(2026, 12, 28));
      expect(future, isNull);
    });
  });
}
