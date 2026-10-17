import 'package:cajui/src/features/home_widget/application/home_snapshot.dart';
import 'package:cajui/src/features/home_widget/application/home_snapshot_provider.dart';
import 'package:cajui/src/features/home_widget/application/widget_bill.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/review/application/review_providers.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';
import '../review/review_entries.dart';

FixedExpense _bill(String name, int day, {String category = 'rent'}) =>
    FixedExpense(
      id: 'f-$name',
      name: name,
      amount: const Money.fromCents(10000),
      dueDay: day,
      categoryId: category,
      paymentMethodId: 'pix',
    );

LedgerEvent _plan(List<FixedExpense> bills) => PlanDefined(
  id: 'plan-bills',
  setup: MonthSetup(
    cashIncome: const Money.fromCents(500000),
    fixedExpenses: bills,
  ),
);

void main() {
  Future<HomeSnapshot> snapshotOf(
    List<LedgerEvent> events, {
    LocalDate? today,
  }) async {
    final container = ProviderContainer(
      overrides: testOverrides(
        journal: MemoryLedgerJournal(events),
        today: today,
      ),
    );
    addTearDown(container.dispose);
    await container.read(ledgerProvider.future);
    await container.read(reviewedEntriesProvider.future);
    // Numa variável antes de devolver: no `return` de uma função assíncrona,
    // o tipo inferido para `read` vira `FutureOr`, e o Riverpod se perde.
    final snapshot = container.read(homeSnapshotProvider);
    return snapshot!;
  }

  test('RN-1080 · o widget grande leva as contas a vencer do mês seguinte, '
      'com o mês escrito junto do dia', () async {
    // Dia 20: o aluguel (10) e a internet (15) de setembro já venceram, e
    // as de outubro estão em aberto.
    final snapshot = await snapshotOf(samplePlanEvents);

    expect(snapshot.bills, [
      WidgetBill(
        name: 'Aluguel',
        dueOn: LocalDate(2026, 10, 10),
        day: 'vence 10 de out.',
      ),
      WidgetBill(
        name: 'Internet',
        dueOn: LocalDate(2026, 10, 15),
        day: 'vence 15 de out.',
      ),
    ]);
    expect(snapshot.toMap()['bills'], [
      {'name': 'Aluguel', 'dueOn': '2026-10-10', 'day': 'vence 10 de out.'},
      {'name': 'Internet', 'dueOn': '2026-10-15', 'day': 'vence 15 de out.'},
    ]);
  });

  test('RN-1082 · a conta que o gasto do mês já cobriu sai da lista, e a do '
      'mês corrente diz só o dia', () async {
    // No dia 1, R$ 1.100,00 lançados em Aluguel pagam o aluguel; a internet
    // divide a categoria e continua em aberto.
    final snapshot = await snapshotOf([
      ...samplePlanEvents,
      EntryRecorded(
        reviewEntry('pago', categoryId: 'rent', cents: 110000, daysAgo: 19),
      ),
    ], today: LocalDate(2026, 9, 1));

    expect(snapshot.bills, [
      WidgetBill(
        name: 'Internet',
        dueOn: LocalDate(2026, 9, 15),
        day: 'vence dia 15',
      ),
    ]);
  });

  test('no máximo três, as mais próximas primeiro, mesmo de categorias '
      'diferentes; no empate, a ordem do plano', () async {
    final snapshot = await snapshotOf([
      _plan([
        _bill('Água', 25),
        _bill('Luz', 22),
        _bill('Escola', 5),
        _bill('Gás', 22, category: 'home'),
        _bill('Condomínio', 28, category: 'home'),
      ]),
    ]);

    expect(snapshot.bills.map((bill) => bill.name), ['Luz', 'Gás', 'Água']);
    expect(snapshot.bills.first.day, 'vence dia 22');
  });

  test('sem contas com dia em "Minhas contas", a lista vai vazia', () async {
    final snapshot = await snapshotOf(const []);

    expect(snapshot.bills, isEmpty);
    expect(snapshot.toMap()['bills'], isEmpty);
  });

  test('retratos que só diferem nas contas são diferentes: conta paga '
      'redesenha o widget', () {
    final day = LocalDate(2026, 9, 30);
    HomeSnapshot withBills(List<WidgetBill> bills) => HomeSnapshot(
      label: 'Sobra de setembro',
      amount: r'R$ 10,00',
      caption: 'Depois de pagar tudo, pelo que está lançado.',
      validUntil: day,
      reviewDates: const [],
      bills: bills,
    );
    final bill = WidgetBill(name: 'Luz', dueOn: day, day: 'vence dia 30');

    expect(withBills([bill]), isNot(withBills(const [])));
    expect(withBills([bill]), withBills([bill]));
  });
}
