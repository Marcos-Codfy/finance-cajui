import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

/// O espaço que o formatador põe entre `R$` e o número.
const String _nbsp = BrlFormatter.nbsp;

/// Uma compra paga inteira no vale, como chega de outro aparelho: já
/// aconteceu, e não há saldo a conferir na chegada.
Entry _onVoucher(String id, int cents) => Entry.create(
  id: id,
  description: 'Feira',
  amount: Money.fromCents(cents),
  occurredOn: LocalDate(2026, 9, 12),
  category: DefaultCatalog.emptyBook.categoryOf('groceries'),
  today: testToday,
  paymentLines: [
    PaymentLine(
      paymentMethodId: 'voucher',
      kind: PaymentMethodKind.mealVoucher,
      amount: Money.fromCents(cents),
    ),
  ],
).valueOrNull!;

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _open(WidgetTester tester, List<LedgerEvent> events) async {
  tester.view.physicalSize = const Size(390, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(journal: MemoryLedgerJournal(events)),
      child: const CajuiApp(),
    ),
  );
  await _settle(tester);
}

void main() {
  testWidgets('RN-124 · gasto no vale além do saldo: o painel mostra zero, '
      'diz quanto passou e leva a acertar o saldo', (tester) async {
    // O vale tem R$ 650,00; chegam duas compras de R$ 400,00.
    await _open(tester, [
      ...samplePlanEvents,
      EntryRecorded(_onVoucher('a', 40000)),
      EntryRecorded(_onVoucher('b', 40000)),
    ]);

    expect(
      find.text('O vale tem R\$${_nbsp}150,00 lançados além do saldo.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Acertar o saldo'));
    await _settle(tester);

    expect(find.text('Saldo do vale'), findsOneWidget);
    expect(
      find.textContaining('Informe abaixo o saldo que a operadora mostra'),
      findsOneWidget,
    );
  });

  testWidgets('RN-124 · com saldo que cobre, nenhum aviso aparece', (
    tester,
  ) async {
    await _open(tester, [
      ...samplePlanEvents,
      EntryRecorded(_onVoucher('a', 40000)),
    ]);

    expect(find.textContaining('lançados além do saldo'), findsNothing);
  });
}
