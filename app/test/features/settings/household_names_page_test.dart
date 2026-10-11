import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:cajui/src/features/ledger/infrastructure/no_ledger_uplink.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/home_navigation.dart';
import '../../support/household_book.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/test_scope.dart';

/// Abre Ajustes com [events] no livro; com [open], entra em "Nomes da
/// casa".
Future<MemoryLedgerJournal> _settings(
  WidgetTester tester, {
  List<LedgerEvent> events = const [],
  LedgerUplink? uplink,
  bool open = true,
}) async {
  tester.view.physicalSize = const Size(400, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final journal = MemoryLedgerJournal(events);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(journal: journal, uplink: uplink),
      child: const CajuiApp(),
    ),
  );
  await tester.pump();
  await openFromHome(tester, 'Ajustes');
  if (open) {
    await tester.tap(find.text('Nomes da casa'));
    await settleAfterTap(tester);
  }
  return journal;
}

bool _canInclude(WidgetTester tester) =>
    tester
        .widget<CajuiButton>(find.widgetWithText(CajuiButton, 'Incluir'))
        .onPressed !=
    null;

void main() {
  testWidgets('RN-1070 · só nome com sobrenome entra; incluir grava a lista '
      'e tirar grava de novo', (tester) async {
    final journal = await _settings(tester);

    await tester.enterText(find.byType(EditableText), 'Marcos');
    await tester.pump();
    expect(_canInclude(tester), isFalse, reason: 'casaria com qualquer Marcos');

    await tester.enterText(find.byType(EditableText), testHouseholdName);
    await tester.pump();
    expect(_canInclude(tester), isTrue);
    await tester.tap(find.text('Incluir'));
    await settleAfterTap(tester);

    expect(find.text(testHouseholdName), findsOneWidget);
    final named = (await journal.readAll()).whereType<HouseholdNamed>();
    expect(named.single.names.names, [testHouseholdName]);

    // A mesma pessoa, abreviada como o banco escreve, já está na lista.
    await tester.enterText(find.byType(EditableText), 'MARCOS V M ARRUDA');
    await tester.pump();
    expect(_canInclude(tester), isFalse);
    expect(
      find.text('Já está na lista, como $testHouseholdName.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Tirar'));
    await settleAfterTap(tester);

    expect(find.text(testHouseholdName), findsNothing);
    final last = (await journal.readAll()).whereType<HouseholdNamed>().last;
    expect(last.names.names, isEmpty);
  });

  testWidgets('RN-1070 · o salário do plano sugere o primeiro nome, para '
      'completar com o sobrenome', (tester) async {
    await _settings(
      tester,
      events: [
        BudgetDefined(
          BudgetPlan(
            salaries: const [
              IncomeSource(
                id: 'cash-income',
                name: 'Salário da Beatriz',
                tender: Tender.cash,
                expectedAmount: Money.fromCents(300000),
                expectedDay: 5,
              ),
            ],
            definedAt: DateTime.utc(2026, 9, 2),
          ),
        ),
      ],
    );

    await tester.tap(find.text('Beatriz'));
    await tester.pump();

    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.controller.text, 'Beatriz ');
    expect(_canInclude(tester), isFalse, reason: 'falta o sobrenome');
  });

  testWidgets('a linha de Ajustes diz quantos nomes há', (tester) async {
    await _settings(
      tester,
      events: [
        householdOf(const [testHouseholdName]),
      ],
      open: false,
    );

    expect(
      find.text('1 nome: Pix entre contas da casa não conta como gasto'),
      findsOneWidget,
    );
  });

  testWidgets('RN-906 · na consulta pela web, que só lê, a linha não '
      'aparece', (tester) async {
    await _settings(tester, uplink: const NoLedgerUplink(), open: false);

    expect(find.text('Nomes da casa'), findsNothing);
  });
}
