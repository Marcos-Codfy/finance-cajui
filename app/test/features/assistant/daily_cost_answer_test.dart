import 'package:cajui/src/features/assistant/application/local_answer.dart';
import 'package:cajui/src/features/budget/application/month_overview.dart';
import 'package:cajui/src/features/insights/application/insights.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_projection.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

/// O livro de quem já cadastrou o plano de exemplo, mais os gastos dados.
LedgerBook _book(List<Entry> entries) {
  var book = samplePlanEvents.fold(
    DefaultCatalog.emptyBook,
    LedgerProjection.apply,
  );
  for (final entry in entries) {
    book = book.copyWith(entries: [...book.entries, entry]);
  }
  return book;
}

Entry _spent(String id, int cents, int day) => Entry.create(
  id: id,
  description: 'Feira',
  amount: Money.fromCents(cents),
  occurredOn: LocalDate(2026, 9, day),
  category: DefaultCatalog.emptyBook.categoryOf('transport'),
  paymentLines: [
    DefaultCatalog.emptyBook.methodOf('pix').line(Money.fromCents(cents)),
  ],
  today: testToday,
).valueOrNull!;

String? _answer(LedgerBook book) {
  final overview = MonthOverview.of(book, testToday);
  return LocalAnswer.of(
    QuestionIntent.dailyCost,
    question: 'quanto dá para gastar por dia?',
    insights: Insights.of(overview, book),
    overview: overview,
    book: book,
  )?.text;
}

void main() {
  group(
    'RN-651 · o custo por dia responde também o que o mês vem custando',
    () {
      test('com gasto no mês, a resposta traz o planejado e o realizado', () {
        // R$ 200,00 gastos até o dia 20: R$ 10,00 por dia.
        final texto = _answer(_book([_spent('e1', 20000, 4)]))!;

        expect(texto, contains('Pelo plano de setembro'));
        expect(texto, contains('Até aqui, o mês vem custando'));
        expect(texto, contains('10,00'));
      });

      test('RN-652 · é média do período, e não o gasto de hoje', () {
        // Os mesmos R$ 200,00, lançados hoje: a média não muda.
        final texto = _answer(_book([_spent('e1', 20000, 20)]))!;

        expect(texto, contains('10,00'));
      });

      test('sem gasto nenhum, a frase do realizado não aparece: zero por dia '
          'seria ruído', () {
        final texto = _answer(_book(const []))!;

        expect(texto, contains('Pelo plano de setembro'));
        expect(texto, isNot(contains('Até aqui')));
      });
    },
  );
}
