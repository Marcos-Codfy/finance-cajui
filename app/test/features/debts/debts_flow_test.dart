import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await _settle(tester);
}

Finder _field(String label) => find.descendant(
  of: find.ancestor(
    of: find.text(label),
    matching: find.byType(CajuiFieldFrame),
  ),
  matching: find.byType(EditableText),
);

/// Abre o app já na tela de dívidas.
Future<MemoryLedgerJournal> _openDebts(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final journal = MemoryLedgerJournal(samplePlanEvents);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(journal: journal),
      child: const CajuiApp(),
    ),
  );
  await tester.pump();
  await _tap(tester, find.bySemanticsLabel('Ajustes'));
  await _tap(tester, find.text('Dívidas'));
  return journal;
}

void main() {
  testWidgets('RN-541 · cadastrar uma dívida: a lista fala primeiro do que '
      'falta, com o já pago ao lado', (tester) async {
    final journal = await _openDebts(tester);
    expect(find.text('Nenhuma dívida cadastrada'), findsOneWidget);

    await _tap(tester, find.text('Cadastrar dívida'));
    await tester.enterText(_field('A quem você deve'), 'Empréstimo Banco X');
    await _settle(tester);
    await tester.enterText(_field('Valor da parcela'), '21200');
    await _settle(tester);
    await _tap(tester, find.text('Quantas já foram pagas'));
    await _tap(tester, find.text('5'));
    await _tap(tester, find.text('Cadastrar'));

    expect(find.text('Empréstimo Banco X'), findsOneWidget);
    expect(find.textContaining(r'Faltam 7 parcelas de R$'), findsOneWidget);
    expect(find.textContaining('5 de 12 pagas'), findsOneWidget);
    expect((await journal.readAll()).whereType<DebtDefined>(), hasLength(1));
  });

  testWidgets('RN-520 · pagar a parcela vira lançamento e a dívida anda', (
    tester,
  ) async {
    final journal = await _openDebts(tester);
    await _tap(tester, find.text('Cadastrar dívida'));
    await tester.enterText(_field('A quem você deve'), 'Empréstimo Banco X');
    await _settle(tester);
    await tester.enterText(_field('Valor da parcela'), '21200');
    await _settle(tester);
    await _tap(tester, find.text('Cadastrar'));

    await _tap(tester, find.text('Empréstimo Banco X'));
    await _tap(tester, find.text('Paguei a parcela deste mês'));
    await _tap(tester, find.text('Por onde foi pago'));
    await _tap(tester, find.text('Pix'));
    await _tap(tester, find.text('Registrar pagamento'));

    // De volta na dívida: uma parcela a menos por pagar.
    expect(find.textContaining('1 de 12 parcelas'), findsOneWidget);
    final paid = (await journal.readAll()).whereType<DebtInstallmentPaid>();
    expect(paid, hasLength(1));
    expect(
      (await journal.readAll())
          .whereType<EntryRecorded>()
          .single
          .entry
          .amount
          .cents,
      21200,
    );
  });
}
