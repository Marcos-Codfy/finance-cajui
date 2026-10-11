import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/home_navigation.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/test_scope.dart';

/// O espaço que o formatador põe entre `R$` e o número.
const String _nbsp = BrlFormatter.nbsp;

String _brl(String digits) => 'R\$$_nbsp$digits';

BudgetLine _line(String id, int cents, LineGroup group, String category) =>
    BudgetLine.create(
      id: id,
      name: id,
      amount: Money.fromCents(cents),
      group: group,
      categoryId: category,
    ).valueOrNull!;

/// Uma casa inventada, com conta de cabeça: salário de [salary], aluguel de
/// R$ 1.000,00 e mercado de R$ 800,00. Sem vale e sem dízimo, o limite da
/// semana é (salário − aluguel) ÷ 4.
BudgetDefined _plan({int salary = 300000}) => BudgetDefined(
  BudgetPlan(
    salaries: [
      IncomeSource(
        id: 'ana',
        name: 'Ana',
        tender: Tender.cash,
        expectedAmount: Money.fromCents(salary),
        expectedDay: 5,
      ),
    ],
    lines: [
      _line('Aluguel', 100000, LineGroup.fixedBill, 'rent'),
      _line('Mercado', 80000, LineGroup.dayToDay, 'groceries'),
    ],
    definedAt: DateTime.utc(2026, 9),
  ),
);

EntryRecorded _bakery(int cents, LocalDate on, {String id = 'padaria'}) =>
    EntryRecorded(
      Entry.create(
        id: id,
        description: 'Padaria',
        amount: Money.fromCents(cents),
        occurredOn: on,
        category: DefaultCatalog.emptyBook.categoryOf('groceries'),
        today: testToday,
        paymentLines: [
          PaymentLine(
            paymentMethodId: 'pix',
            kind: PaymentMethodKind.pix,
            amount: Money.fromCents(cents),
          ),
        ],
      ).valueOrNull!,
    );

Future<MemoryLedgerJournal> _openHome(
  WidgetTester tester,
  List<LedgerEvent> events,
) async {
  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final journal = MemoryLedgerJournal(events);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(journal: journal),
      child: const CajuiApp(),
    ),
  );
  await tester.pump();
  await tester.tap(find.bySemanticsLabel('Início'));
  await settleAfterTap(tester);
  return journal;
}

void main() {
  testWidgets('RN-1010 RN-1011 · com o plano, o Início diz quanto dá para '
      'gastar na semana e quanto sobra no mês', (tester) async {
    await _openHome(tester, [_plan()]);

    expect(find.text('Pode gastar esta semana'), findsOneWidget);
    // (3.000 − 1.000) ÷ 4 = 500.
    expect(
      find.text('${_brl('0,00')} de ${_brl('500,00')} já gastos'),
      findsOneWidget,
    );
    // 3.000 − 1.000 − 800 = 1.200, e 1.800 de 3.000 = 60%.
    expect(find.text('Sobra de setembro'), findsOneWidget);
    expect(find.text(_brl('1.200,00')), findsOneWidget);
    expect(
      find.text('Depois de pagar tudo · 60% da renda já está gasto'),
      findsOneWidget,
    );
  });

  testWidgets('RN-1011 · o gasto da semana sai do que dá para gastar', (
    tester,
  ) async {
    await _openHome(tester, [_plan(), _bakery(12000, testToday)]);

    expect(find.text(_brl('380,00')), findsOneWidget);
    expect(
      find.text('${_brl('120,00')} de ${_brl('500,00')} já gastos'),
      findsOneWidget,
    );
  });

  testWidgets('RN-1060 · mês que não fecha diz quanto falta, sem alarme', (
    tester,
  ) async {
    await _openHome(tester, [_plan(salary: 150000)]);

    // 1.500 − 1.000 − 800 = −300.
    expect(find.textContaining('Faltam para fechar'), findsOneWidget);
    expect(find.text(_brl('300,00')), findsOneWidget);
    expect(find.textContaining('déficit'), findsNothing);
    expect(find.textContaining('!'), findsNothing);
  });

  testWidgets('RN-1050 · sem plano, o Início mostra o que já saiu, e o '
      'plano não é cobrado', (tester) async {
    await _openHome(tester, [_bakery(4500, testToday)]);

    expect(find.text('Já saiu este mês'), findsOneWidget);
    expect(find.text(_brl('45,00')), findsOneWidget);
    expect(find.text('Pode gastar esta semana'), findsNothing);
    expect(find.text('Usar como minhas contas'), findsNothing);
  });

  testWidgets('RN-1050 · depois de um mês sem plano, o Início sugere as '
      'contas, e aceitar grava o plano', (tester) async {
    final journal = await _openHome(tester, [
      _bakery(30000, LocalDate(2026, 8, 10), id: 'agosto'),
      _bakery(41000, LocalDate(2026, 9, 2), id: 'setembro'),
    ]);

    expect(find.text('Usar como minhas contas'), findsOneWidget);

    await tester.tap(find.text('Usar como minhas contas'));
    await settleAfterTap(tester);

    final defined = (await journal.readAll()).whereType<BudgetDefined>();
    expect(defined, hasLength(1));
    expect(defined.single.plan.lines, isNotEmpty);
    expect(find.text('Usar como minhas contas'), findsNothing);
  });
}
