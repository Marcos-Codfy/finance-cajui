import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_inbox.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/test_scope.dart';

/// Salário de R$ 3.000,00 e aluguel de R$ 1.000,00: R$ 500,00 por semana.
BudgetDefined _plan() => BudgetDefined(
  BudgetPlan(
    salaries: const [
      IncomeSource(
        id: 'ana',
        name: 'Ana',
        tender: Tender.cash,
        expectedAmount: Money.fromCents(300000),
        expectedDay: 5,
      ),
    ],
    lines: [
      BudgetLine.create(
        id: 'Aluguel',
        name: 'Aluguel',
        amount: const Money.fromCents(100000),
        group: LineGroup.fixedBill,
        categoryId: 'rent',
      ).valueOrNull!,
    ],
    definedAt: DateTime.utc(2026, 9),
  ),
);

Future<FakeInbox> _open(WidgetTester tester, List<LedgerEvent> events) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final inbox = FakeInbox();
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(
        journal: MemoryLedgerJournal(events),
        inbox: inbox,
      ),
      child: const CajuiApp(),
    ),
  );
  await tester.pump();
  return inbox;
}

void main() {
  testWidgets('sugestão 3 · a conversa abre com o nome da Juju e o pode '
      'gastar da semana no alto', (tester) async {
    await _open(tester, [_plan()]);

    expect(
      find.descendant(
        of: find.byType(CajuiScreen),
        matching: find.text(AssistantIdentity.name),
      ),
      findsWidgets,
    );
    // O sobretítulo é em versalete: o texto chega em maiúsculas.
    expect(
      find.text('PODE GASTAR R\$${BrlFormatter.nbsp}500,00 NESTA SEMANA'),
      findsOneWidget,
    );
  });

  testWidgets('RN-1050 · sem plano, o alto da conversa diz o que já saiu', (
    tester,
  ) async {
    await _open(tester, const []);

    expect(
      find.text('JÁ SAIU R\$${BrlFormatter.nbsp}0,00 ESTE MÊS'),
      findsOneWidget,
    );
  });

  testWidgets('a câmera fica à mão na conversa, sem trocar de aba', (
    tester,
  ) async {
    final inbox = await _open(tester, [_plan()]);

    await tester.tap(find.bySemanticsLabel('Fotografar comprovante').first);
    await tester.pump();

    expect(inbox.photoRequests, 1);
  });
}
