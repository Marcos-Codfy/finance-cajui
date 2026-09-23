import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

void main() {
  group('Entry', () {
    test('RN-201 registra o que foi comprado e por onde foi pago', () {
      final created = entry(cents: 18640, lines: [pix(18640)]);

      expect(created.description, 'Mercado Boa Compra');
      expect(created.amount, const Money.fromCents(18640));
      expect(created.occurredOn, LocalDate(2026, 9, 12));
      expect(created.categoryId, 'groceries');
    });

    test('RN-203 e RN-204 aceita pagamento dividido com soma exata', () {
      final created = entry(cents: 8600, lines: [voucher(3000), pix(5600)]);

      expect(created.paidByTender.mealVoucher, const Money.fromCents(3000));
      expect(created.paidByTender.cash, const Money.fromCents(5600));
    });

    test('RN-203 soma das linhas diferente do valor é recusada', () {
      final failure = tryEntry(
        cents: 8600,
        lines: [voucher(3000), pix(5000)],
      ).failureOrNull;

      expect(failure, isA<PaymentLinesMismatch>());
      expect(
        (failure! as PaymentLinesMismatch).difference,
        const Money.fromCents(600),
      );
    });

    test('RN-104 valor zero ou negativo é recusado', () {
      expect(
        tryEntry(cents: 0, lines: [pix(0)]).failureOrNull,
        isA<NonPositiveAmount>(),
      );
      expect(
        tryEntry(cents: 100, lines: [pix(200), pix(-100)]).failureOrNull,
        isA<NonPositiveAmount>(),
      );
    });

    test('RN-206 data no futuro é recusada; a de hoje é aceita', () {
      final tomorrow = tryEntry(
        cents: 500,
        lines: [pix(500)],
        on: today.addDays(1),
      );

      expect(tomorrow.failureOrNull, isA<PurchaseDateInFuture>());
      expect(tryEntry(cents: 500, lines: [pix(500)], on: today).isOk, isTrue);
    });

    test('RN-112 o vale só paga categoria elegível', () {
      final failure = tryEntry(
        cents: 9900,
        lines: [voucher(9900)],
        category: internet,
      ).failureOrNull;

      expect(failure, isA<CategoryNotVoucherEligible>());
      expect((failure! as CategoryNotVoucherEligible).categoryName, 'Internet');
    });

    test('RN-205 a moeda da linha vem da forma de pagamento', () {
      expect(voucher(100).tender, Tender.mealVoucher);
      expect(pix(100).tender, Tender.cash);
      expect(credit(100).tender, Tender.cash);
    });

    test('as linhas de um lançamento criado não podem ser alteradas', () {
      final created = entry(cents: 500, lines: [pix(500)]);

      expect(() => created.paymentLines.add(pix(1)), throwsUnsupportedError);
    });
  });

  group('Reversal', () {
    final split = entry(cents: 8600, lines: [voucher(3000), pix(5600)]);

    Result<Reversal> reverse(
      int cents, {
      String method = 'pix',
      List<Reversal> previous = const [],
    }) => Reversal.create(
      id: 'r${previous.length}',
      entry: split,
      paymentMethodId: method,
      amount: Money.fromCents(cents),
      occurredOn: LocalDate(2026, 10, 2),
      previous: previous,
    );

    test('RN-209 conta no mês da data do estorno, não no da compra', () {
      final reversal = reverse(5600).valueOrNull!;

      expect(reversal.occurredOn.budgetMonth, const BudgetMonth(2026, 10));
      expect(split.occurredOn.budgetMonth, const BudgetMonth(2026, 9));
    });

    test('RN-211 volta pela mesma forma de pagamento e na mesma moeda', () {
      final reversal = reverse(3000, method: 'voucher').valueOrNull!;

      expect(reversal.line.tender, Tender.mealVoucher);
      expect(reversal.line.paymentMethodId, 'voucher');
    });

    test('RN-210 a soma dos estornos nunca passa do que foi pago', () {
      final first = reverse(4000).valueOrNull!;

      final second = reverse(2000, previous: [first]);

      expect(second.failureOrNull, isA<ReversalExceedsRemaining>());
      expect(
        (second.failureOrNull! as ReversalExceedsRemaining).remaining,
        const Money.fromCents(1600),
      );
      expect(reverse(1600, previous: [first]).isOk, isTrue);
    });

    test('RN-104 estorno de valor zero é recusado', () {
      expect(reverse(0).failureOrNull, isA<NonPositiveAmount>());
    });

    test('BL-055 estornar por uma forma que o lançamento não usou é falha, '
        'e não exceção: quem relê o registro não pode quebrar', () {
      final recusa = reverse(1000, method: 'boleto');

      expect(recusa.failureOrNull, isA<ReversalExceedsRemaining>());
      expect(
        (recusa.failureOrNull! as ReversalExceedsRemaining).remaining,
        Money.zero,
        reason: 'linha que não existe tem zero a estornar',
      );
    });
  });

  group('PossibleDuplicate', () {
    test('RN-221 mesmo valor, data e estabelecimento equivalente avisam', () {
      final first = entry(
        cents: 850,
        lines: [pix(850)],
        description: 'PADARIA CENTRAL LTDA.',
      );
      final second = entry(
        id: 'e2',
        cents: 850,
        lines: [pix(850)],
        description: 'Padaria  Central',
      );

      expect(PossibleDuplicate.matches(second, first), isTrue);
    });

    test('RN-221 valor, data ou lugar diferente não avisa', () {
      final base = entry(cents: 850, lines: [pix(850)], description: 'Padaria');
      Entry other({int cents = 850, LocalDate? on, String where = 'Padaria'}) =>
          entry(
            id: 'e2',
            cents: cents,
            lines: [pix(cents)],
            on: on,
            description: where,
          );

      expect(PossibleDuplicate.matches(other(cents: 900), base), isFalse);
      expect(
        PossibleDuplicate.matches(other(on: LocalDate(2026, 9, 13)), base),
        isFalse,
      );
      expect(PossibleDuplicate.matches(other(where: 'Açougue'), base), isFalse);
      expect(PossibleDuplicate.matches(base, base), isFalse);
    });
    test('RN-221 · o comprovante que ainda não é lançamento acha o que já '
        'existe, por valor, data e lugar', () {
      final book = [
        entry(cents: 850, lines: [pix(850)], description: 'PADARIA CENTRAL'),
        entry(id: 'e2', cents: 2000, lines: [pix(2000)], description: 'Feira'),
      ];

      final achado = PossibleDuplicate.among(
        book,
        amount: const Money.fromCents(850),
        occurredOn: book.first.occurredOn,
        description: 'Padaria  Central Ltda.',
      );
      final nenhum = PossibleDuplicate.among(
        book,
        amount: const Money.fromCents(850),
        occurredOn: book.first.occurredOn,
        description: 'Açougue',
      );

      expect(achado?.id, book.first.id);
      expect(nenhum, isNull);
    });
  });

  group('ExceptionalSpending', () {
    test('RN-240 e RN-241 soma entre categorias e dá a média do ano', () {
      Entry exceptional(String id, int cents, int month, Category category) =>
          entry(
            id: id,
            cents: cents,
            lines: [pix(cents)],
            category: category,
            on: LocalDate(2026, month, 5),
            isExceptional: true,
          );
      final entries = [
        exceptional('a', 42000, 2, leisure),
        exceptional('b', 31000, 5, internet),
        exceptional('c', 28000, 7, leisure),
        exceptional('d', 30000, 9, groceries),
        entry(id: 'comum', cents: 5000, lines: [pix(5000)]),
      ];

      final summary = ExceptionalSpending.of(
        entries,
        upTo: const BudgetMonth(2026, 9),
      );

      expect(summary.count, 4);
      expect(summary.total, const Money.fromCents(131000));
      // 1.310,00 ÷ 9 meses = 145,555… → 145,56
      expect(summary.monthlyAverage, const Money.fromCents(14556));
    });
  });
}
