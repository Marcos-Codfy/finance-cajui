import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/entry_days.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_scope.dart';

Entry _entry(String id, int cents, LocalDate on, {String method = 'pix'}) {
  final book = DefaultCatalog.emptyBook;
  return Entry.create(
    id: id,
    description: id,
    amount: Money.fromCents(cents),
    occurredOn: on,
    category: book.categoryOf('groceries'),
    paymentLines: [book.methodOf(method).line(Money.fromCents(cents))],
    today: testToday,
  ).valueOrNull!;
}

void main() {
  group('os lançamentos por dia', () {
    final today = testToday;
    final yesterday = today.addDays(-1);

    test('um grupo por dia, na ordem em que a lista vem', () {
      final days = EntryDays.of([
        _entry('a', 1000, today),
        _entry('b', 2000, today),
        _entry('c', 3000, yesterday),
      ]);

      expect([for (final day in days) day.day], [today, yesterday]);
      expect([for (final e in days.first.entries) e.id], ['a', 'b']);
    });

    test('RN-111 · o total do dia separa dinheiro e vale, nunca soma', () {
      final [day] = EntryDays.of([
        _entry('mercado', 5000, today),
        _entry('feira', 2000, today, method: 'voucher'),
      ]);

      expect(day.spent.cash, const Money.fromCents(5000));
      expect(day.spent.mealVoucher, const Money.fromCents(2000));
    });

    test('lista vazia não tem dia nenhum', () {
      expect(EntryDays.of(const []), isEmpty);
    });
  });
}
