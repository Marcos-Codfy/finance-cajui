import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/core/settings/event_store_preferences.dart';
import 'package:cajui/src/core/storage/memory_event_store.dart';
import 'package:cajui/src/features/home/presentation/month_celebration.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/home_navigation.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/test_scope.dart';

BudgetLine _rent() => BudgetLine.create(
  id: 'Aluguel',
  name: 'Aluguel',
  amount: const Money.fromCents(100000),
  group: LineGroup.fixedBill,
  categoryId: 'rent',
).valueOrNull!;

/// Uma casa inventada: salário de [salary] e aluguel de R$ 1.000,00.
BudgetDefined _plan(int salary) => BudgetDefined(
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
    lines: [_rent()],
    definedAt: DateTime.utc(2026, 9),
  ),
);

Future<void> _openHome(WidgetTester tester, List<LedgerEvent> events) async {
  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(journal: MemoryLedgerJournal(events)),
      child: const CajuiApp(),
    ),
  );
  await tester.pump();
  await tester.tap(find.bySemanticsLabel('Início'));
  await settleAfterTap(tester);
}

/// O brilho do cartão do resultado do mês. Cada cartão do carrossel tem o
/// seu, e só o da sobra se acende.
CajuiGlow _glow(WidgetTester tester) => tester.widget<CajuiGlow>(
  find.descendant(
    of: find.ancestor(
      of: find.textContaining(RegExp('^(Sobra de|Faltam para fechar)')),
      matching: find.byType(CajuiStatCard),
    ),
    matching: find.byType(CajuiGlow),
  ),
);

void main() {
  group('MonthCelebration · a festa do mês no verde é uma vez por mês', () {
    const october = BudgetMonth(2026, 10);

    test('escondida, não há festa; à vista, há', () {
      final festa = MonthCelebration(EventStorePreferences(MemoryEventStore()));

      expect(festa.party(october, visible: false), isFalse);
      expect(festa.party(october, visible: true), isTrue);
    });

    test('começada, continua até o app fechar, mesmo escondida', () {
      final festa = MonthCelebration(EventStorePreferences(MemoryEventStore()))
        ..mark(october);

      expect(festa.party(october, visible: false), isTrue);
    });

    test('na próxima abertura, o mesmo mês não tem festa de novo; o '
        'seguinte tem', () async {
      final store = MemoryEventStore();
      MonthCelebration(EventStorePreferences(store)).mark(october);
      await Future<void>.delayed(Duration.zero);

      final reopened = MonthCelebration(EventStorePreferences(store));

      expect(reopened.party(october, visible: true), isFalse);
      expect(reopened.party(october.next, visible: true), isTrue);
    });
  });

  testWidgets('a conversa à vista não gasta a festa do mês no Início '
      'escondido; tocar em Início faz a festa', (tester) async {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(journal: MemoryLedgerJournal([_plan(300000)])),
        child: const CajuiApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(CajuiGlow, skipOffstage: false), findsNothing);

    await tester.tap(find.bySemanticsLabel('Início'));
    await settleAfterTap(tester);

    expect(_glow(tester).celebrateOnAppear, isTrue);
  });

  testWidgets('o pote e o pode gastar da semana saíram do Início (pedido do '
      'dono, 11/10)', (tester) async {
    await _openHome(tester, [_plan(300000)]);

    expect(find.textContaining('Pode gastar'), findsNothing);
    expect(find.textContaining('semana'), findsNothing);
  });

  testWidgets('escolha 5 · o mês que fecha no verde brilha, com festa na '
      'primeira vez à vista', (tester) async {
    await _openHome(tester, [_plan(300000)]);

    expect(_glow(tester).active, isTrue);
    expect(_glow(tester).celebrateOnAppear, isTrue);
  });

  testWidgets('RN-1060 · o mês em que falta não brilha', (tester) async {
    await _openHome(tester, [_plan(80000)]);

    expect(find.textContaining('Faltam para fechar'), findsOneWidget);
    expect(_glow(tester).active, isFalse);
  });
}
