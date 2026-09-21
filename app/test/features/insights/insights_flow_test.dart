import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/infrastructure/memory_ledger_journal.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

/// O espaço que o formato da casa põe entre `R$` e o número.
const String _nbsp = BrlFormatter.nbsp;

Entry _bought(String id, String what, int cents, PaymentLine line) =>
    Entry.create(
      id: id,
      description: what,
      amount: Money.fromCents(cents),
      occurredOn: testToday,
      category: DefaultCatalog.emptyBook.categoryOf('groceries'),
      paymentLines: [line],
      today: testToday,
    ).valueOrNull!;

/// O plano de exemplo, mais duas compras de hoje: uma no Pix, outra no vale.
List<LedgerEvent> _events() {
  final book = DefaultCatalog.emptyBook;
  final pix = book.methodOf('pix').line(const Money.fromCents(850));
  final voucher = book.methodOf('voucher').line(const Money.fromCents(3840));
  return [
    ...samplePlanEvents,
    EntryRecorded(_bought('e1', 'Padaria', 850, pix)),
    EntryRecorded(_bought('e2', 'Mercado', 3840, voucher)),
  ];
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

void main() {
  testWidgets('os três resumos, no aparelho e sem rede: o dia com as duas '
      'moedas separadas, a semana com o limite, o mês nas duas partes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(journal: MemoryLedgerJournal(_events())),
        child: const CajuiApp(),
      ),
    );
    await _settle(tester);

    // RN-810: a frase de hoje já aparece no painel, na porta dos resumos.
    const today =
        'Hoje: R\$${_nbsp}8,50 em dinheiro · R\$${_nbsp}38,40 no vale, em 2 '
        'lançamentos.';
    expect(find.text(today), findsOneWidget);

    await tester.tap(find.text('Resumos'));
    await _settle(tester);

    // RN-804: nenhum total que some dinheiro e vale.
    expect(find.text(today), findsOneWidget);
    expect(find.textContaining('46,90'), findsNothing);

    await tester.tap(find.text('Semana'));
    await _settle(tester);
    expect(find.textContaining('Semana de 14 a 20:'), findsOneWidget);

    await tester.tap(find.text('Mês'));
    await _settle(tester);
    expect(find.text('Como foi o mês'), findsOneWidget);
    expect(find.text('Como fica adiante'), findsOneWidget);
    expect(find.text('2 de 2 variáveis dentro do previsto.'), findsOneWidget);
  });
}
