import 'dart:async';

import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/core/navigation/coordinator_access.dart';
import 'package:cajui/src/features/budget/presentation/budget_coordinator.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/infrastructure/no_ledger_uplink.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_uplink.dart';
import '../../support/home_navigation.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/test_scope.dart';

/// O espaço que o formatador põe entre `R$` e o número.
String _brl(String digits) => 'R\$${BrlFormatter.nbsp}$digits';

/// O crédito de R$ 170,00 do exemplo da RN-123.
final LedgerEvent _credit = IncomeReceived(
  IncomeReceipt(
    id: 'credito',
    tender: Tender.mealVoucher,
    amount: const Money.fromCents(17000),
    receivedOn: testToday,
  ),
);

Finder _field(String label) => find.descendant(
  of: find.ancestor(
    of: find.text(label),
    matching: find.byType(CajuiFieldFrame),
  ),
  matching: find.byType(EditableText),
);

Future<ProviderContainer> _openVoucher(
  WidgetTester tester, {
  bool paired = true,
}) async {
  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final scope = ProviderScope(
    overrides: testOverrides(
      journal: MemoryLedgerJournal([_credit]),
      uplink: paired ? FakeUplink() : const NoLedgerUplink(),
    ),
    child: const CajuiApp(),
  );
  await tester.pumpWidget(scope);
  await tester.pump();
  if (paired) {
    await openFromHome(tester, 'Vale');
  } else {
    // Na web sem lançamento, o Início é a tela vazia, sem as portas.
    unawaited(
      tester
          .element(find.byType(CajuiScreen).first)
          .coordinator(budgetCoordinatorProvider)
          .openVoucher(),
    );
    await settleAfterTap(tester);
  }
  return ProviderScope.containerOf(tester.element(find.byType(CajuiApp)));
}

void main() {
  testWidgets('BL-079 · o Início tem a porta do vale, com o saldo', (
    tester,
  ) async {
    await _openVoucher(tester);

    expect(find.text('Saldo do vale'), findsOneWidget);
    expect(find.text(_brl('170,00')), findsWidgets);
  });

  testWidgets(r'RN-123 · a operadora diz R$ 162,10: o Cajui acerta −R$ 7,90, '
      'e o saldo passa a ser o dela', (tester) async {
    final container = await _openVoucher(tester);

    await tester.enterText(_field('O app da operadora diz'), '16210');
    await tester.pump();
    await tester.tap(find.text('Acertar o saldo'));
    await settleAfterTap(tester);

    final book = await container.read(ledgerProvider.future);
    expect(book.voucherAdjustments.single.amount, const Money.fromCents(-790));
    expect(book.voucher.balance, const Money.fromCents(16210));
    expect(find.textContaining('Saldo acertado'), findsOneWidget);
  });

  testWidgets(r'RN-123 · a operadora diz R$ 0,00: dá para zerar, e a tela '
      'passa a dizer que o vale foi todo usado', (tester) async {
    final container = await _openVoucher(tester);

    await tester.enterText(_field('O app da operadora diz'), '0');
    await tester.pump();
    await tester.tap(find.text('Acertar o saldo'));
    await settleAfterTap(tester);

    final book = await container.read(ledgerProvider.future);
    expect(
      book.voucherAdjustments.single.amount,
      const Money.fromCents(-17000),
    );
    expect(book.voucher.balance, Money.zero);
    expect(
      find.text('O vale foi todo usado, pelo que está lançado.'),
      findsOneWidget,
    );
  });

  testWidgets('na consulta pela web, o vale só se lê: sem acerto', (
    tester,
  ) async {
    await _openVoucher(tester, paired: false);

    expect(find.text('Saldo do vale'), findsOneWidget);
    expect(find.text('Acertar o saldo'), findsNothing);
  });

  testWidgets('BL-079 · com o vale só no plano, a porta diz o vale do mês, e '
      r'não "saldo de R$ 0,00"', (tester) async {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(
          journal: MemoryLedgerJournal([
            BudgetDefined(
              BudgetPlan(
                voucher: const Money.fromCents(50000),
                definedAt: DateTime.utc(2026, 9),
              ),
            ),
          ]),
        ),
        child: const CajuiApp(),
      ),
    );
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Painel'));
    await settleAfterTap(tester);
    await tester.ensureVisible(find.bySemanticsLabel('Mais'));
    await tester.tap(find.bySemanticsLabel('Mais'));
    await settleAfterTap(tester);

    expect(
      find.text('Vale do mês ${_brl('500,00')} · conferir com a operadora'),
      findsOneWidget,
    );
  });
}
