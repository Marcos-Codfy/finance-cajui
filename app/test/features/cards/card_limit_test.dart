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
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

/// O espaço que o formatador põe entre `R$` e o número.
const String _nbsp = BrlFormatter.nbsp;

CreditCard _card({int? limitCents}) => CreditCard.create(
  id: 'card-1',
  name: 'Cartão da casa',
  closingDay: 25,
  dueDay: 5,
  creditLimit: limitCents == null ? null : Money.fromCents(limitCents),
).valueOrNull!;

/// Mercado de R$ 800,00 à vista no cartão, em 12/09: fatura de outubro.
Entry _market() => Entry.create(
  id: 'mercado',
  description: 'Mercado do mês',
  amount: const Money.fromCents(80000),
  occurredOn: LocalDate(2026, 9, 12),
  category: DefaultCatalog.emptyBook.categoryOf('groceries'),
  today: testToday,
  paymentLines: const [
    PaymentLine(
      paymentMethodId: 'card-1',
      kind: PaymentMethodKind.creditCard,
      amount: Money.fromCents(80000),
    ),
  ],
).valueOrNull!;

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await _settle(tester);
}

Future<void> _openCards(WidgetTester tester, CreditCard card) async {
  tester.view.physicalSize = const Size(390, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(
        journal: MemoryLedgerJournal([
          ...samplePlanEvents,
          CardDefined(id: 'card-fact-1', card: card),
          EntryRecorded(_market()),
        ]),
      ),
      child: const CajuiApp(),
    ),
  );
  await _settle(tester);
  await openFromHome(tester, 'Cartões');
}

void main() {
  testWidgets(
    'RN-305 RN-1020 · o limite livre aparece na lista e na fatura, com o '
    'que está tomado dito por extenso',
    (tester) async {
      await _openCards(tester, _card(limitCents: 500000));

      // RN-1020: o uso do mês são as compras do mês no cartão.
      expect(
        find.text(
          'Usei R\$${_nbsp}800,00 este mês · sobra R\$${_nbsp}4.200,00 · '
          'fecha dia 25 · vence dia 5',
        ),
        findsOneWidget,
      );
      // 16% do limite: abaixo da metade, nenhum aviso.
      expect(find.byType(CajuiNotice), findsNothing);
      // Escolha 2 do dono: com limite, o cartão aparece em 3D.
      expect(find.byType(CajuiCreditCard3D), findsOneWidget);

      await _tap(tester, find.bySemanticsLabel('Cartão da casa, ver a fatura'));

      expect(find.text('Limite livre'), findsOneWidget);
      expect(
        find.text(
          'R\$${_nbsp}800,00 tomados de R\$${_nbsp}5.000,00: faturas em aberto '
          'e parcelas por vencer.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('RN-305 · passar do limite não vira alarme: a frase diz quanto '
      'passou', (tester) async {
    await _openCards(tester, _card(limitCents: 50000));
    await _tap(tester, find.bySemanticsLabel('Cartão da casa, ver a fatura'));

    expect(
      find.textContaining('O tomado passou R\$${_nbsp}300,00 do limite'),
      findsOneWidget,
    );
    expect(find.textContaining('!'), findsNothing);
  });

  testWidgets('RN-302 · cartão sem limite informado não mostra limite '
      'nenhum', (tester) async {
    await _openCards(tester, _card());

    expect(find.text('fecha dia 25 · vence dia 5'), findsOneWidget);
    expect(find.byType(CajuiCreditCard3D), findsNothing);

    await _tap(tester, find.bySemanticsLabel('Cartão da casa, ver a fatura'));

    expect(find.text('Limite livre'), findsNothing);
  });
}
