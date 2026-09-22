import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_ledger_journal.dart';
import '../../support/test_scope.dart';

/// Abre o app já na aba de lançamentos.
Future<void> _openEntries(
  WidgetTester tester,
  MemoryLedgerJournal journal,
) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(journal: journal),
      child: const CajuiApp(),
    ),
  );
  await tester.pump();
  await tester.tap(find.bySemanticsLabel('Lançamentos'));
  await _settle(tester);
}

/// Deixa as trocas de tela terminarem. `pumpAndSettle` não serve: o
/// esqueleto de carregamento pulsa sem parar.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _choose(WidgetTester tester, String field, String option) async {
  await tester.tap(find.text(field));
  await _settle(tester);
  await tester.tap(find.text(option));
  await _settle(tester);
}

Finder _field(String label) => find.descendant(
  of: find.ancestor(
    of: find.text(label),
    matching: find.byType(CajuiFieldFrame),
  ),
  matching: find.byType(EditableText),
);

void main() {
  testWidgets('UC-ENTRY-01 · lançar ônibus de 8,50 no Pix: aparece na lista, '
      'com o que foi em cima e por onde foi pago embaixo', (tester) async {
    final journal = MemoryLedgerJournal();
    await _openEntries(tester, journal);

    await tester.tap(find.text('Lançar'));
    await _settle(tester);
    await tester.enterText(_field('Valor'), '850');
    await tester.enterText(_field('O que foi'), 'Ônibus');
    await _choose(tester, 'Categoria', 'Transporte');
    await _choose(tester, 'Por onde foi pago', 'Pix');
    await tester.tap(find.text('Lançar'));
    await _settle(tester);

    expect(find.text('Nova despesa'), findsNothing);
    expect(find.text('Ônibus'), findsOneWidget);
    expect(find.text('Transporte · Pix · hoje'), findsOneWidget);
    expect(await journal.readAll(), hasLength(1));
  });

  testWidgets('E-ENTRY-03 · valor zerado: o texto fica sob o campo, e nada é '
      'gravado', (tester) async {
    final journal = MemoryLedgerJournal();
    await _openEntries(tester, journal);

    await tester.tap(find.text('Lançar'));
    await _settle(tester);
    await tester.enterText(_field('O que foi'), 'Ônibus');
    await _choose(tester, 'Categoria', 'Transporte');
    await _choose(tester, 'Por onde foi pago', 'Pix');
    await tester.tap(find.text('Lançar'));
    await _settle(tester);

    expect(find.textContaining('Digite um valor maior que zero'), findsOne);
    expect(find.text('Nova despesa'), findsOneWidget);
    expect(await journal.readAll(), isEmpty);
  });

  testWidgets('RN-111 · o mês mostra dinheiro e vale em linhas separadas, e '
      'nenhum total', (tester) async {
    final book = MemoryLedgerJournal([
      VoucherBalanceAdjusted(
        id: 'a1',
        adjustment: const Money.fromCents(3000),
        on: testToday,
        reason: 'teste',
      ),
    ]);
    await _openEntries(tester, book);

    expect(find.text('Gasto em dinheiro'), findsOneWidget);
    expect(find.text('Gasto no vale'), findsOneWidget);
    expect(find.textContaining('Total'), findsNothing);
    expect(find.text('Saldo do vale'), findsOneWidget);
  });
}
