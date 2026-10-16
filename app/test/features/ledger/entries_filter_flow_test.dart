import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/home_navigation.dart';
import '../../support/household_book.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/test_scope.dart';

/// Uma compra no débito, para o filtro de forma de pagamento ter o que
/// separar do Pix.
EntryRecorded _onDebit(String id, String description, LocalDate on) =>
    EntryRecorded(
      Entry.create(
        id: id,
        description: description,
        amount: const Money.fromCents(4590),
        occurredOn: on,
        category: DefaultCatalog.categories.firstWhere(
          (c) => c.id == 'groceries',
        ),
        paymentLines: const [
          PaymentLine(
            paymentMethodId: 'debit',
            kind: PaymentMethodKind.debit,
            amount: Money.fromCents(4590),
          ),
        ],
        today: testToday,
      ).valueOrNull!,
    );

/// Três compras em setembro, uma em agosto. Inventadas, como todas.
MemoryLedgerJournal _book() => MemoryLedgerJournal([
  recordedEntry(
    id: 'bakery',
    cents: 1250,
    on: testYesterday,
    description: 'Padaria Pão Quente',
    categoryId: 'bakery',
  ),
  recordedEntry(
    id: 'pharmacy',
    cents: 3200,
    on: LocalDate(2026, 9, 10),
    description: 'FARMACIA SAO JOAO',
    categoryId: 'health',
  ),
  _onDebit('market', 'Mercado Boa Compra', LocalDate(2026, 9, 12)),
  recordedEntry(
    id: 'butcher',
    cents: 5400,
    on: LocalDate(2026, 8, 15),
    description: 'Açougue do Zé',
    categoryId: 'butcher',
  ),
]);

Future<void> _openEntries(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(journal: _book()),
      child: const CajuiApp(),
    ),
  );
  await tester.pump();
  await openFromHome(tester, 'Lançamentos');
  await settleAfterTap(tester);
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.tap(target);
  await settleAfterTap(tester);
}

Finder get _search => find.descendant(
  of: find.ancestor(
    of: find.text('Buscar'),
    matching: find.byType(CajuiFieldFrame),
  ),
  matching: find.byType(EditableText),
);

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(_search, text);
  await settleAfterTap(tester);
}

/// As descrições que estão na lista agora.
void _expectListed(List<String> shown, {List<String> hidden = const []}) {
  for (final description in shown) {
    expect(find.text(description), findsOneWidget, reason: description);
  }
  for (final description in hidden) {
    expect(find.text(description), findsNothing, reason: description);
  }
}

const _september = ['Padaria Pão Quente', 'Mercado Boa Compra'];

void main() {
  testWidgets('a busca ignora caixa e acento, vira chip, e o chip a tira '
      'com um toque', (tester) async {
    await _openEntries(tester);
    _expectListed(
      [..._september, 'FARMACIA SAO JOAO'],
      hidden: ['Açougue do Zé'],
    );

    await _type(tester, 'farmácia são');

    _expectListed(['FARMACIA SAO JOAO'], hidden: _september);
    await _tap(tester, find.text('“farmácia são”'));

    _expectListed([..._september, 'FARMACIA SAO JOAO']);
    expect(tester.widget<EditableText>(_search).controller.text, isEmpty);
  });

  testWidgets('categoria e forma de pagamento se escolhem pelo chip, e '
      'saem com um toque nele', (tester) async {
    await _openEntries(tester);

    await _tap(tester, find.text('Categoria'));
    await _tap(tester, find.text('Padaria'));
    _expectListed(['Padaria Pão Quente'], hidden: ['Mercado Boa Compra']);

    await _tap(tester, find.text('Padaria'));
    expect(find.text('Categoria'), findsOneWidget);
    await _tap(tester, find.text('Forma de pagamento'));
    await _tap(tester, find.text('Débito'));

    _expectListed(['Mercado Boa Compra'], hidden: ['Padaria Pão Quente']);
  });

  testWidgets('filtro sem resultado diz o que tirar, e "Tirar os filtros" '
      'traz a lista de volta', (tester) async {
    await _openEntries(tester);

    await _type(tester, 'posto');
    await _tap(tester, find.text('Categoria'));
    await _tap(tester, find.text('Saúde e farmácia'));

    expect(find.text('Nenhum lançamento com esses filtros'), findsOneWidget);
    expect(
      find.text(
        'Tire a busca “posto” ou a categoria Saúde e farmácia para ver mais.',
      ),
      findsOneWidget,
    );
    expect(find.text('Nada lançado ainda'), findsNothing);

    await _tap(tester, find.text('Tirar os filtros'));
    _expectListed([..._september, 'FARMACIA SAO JOAO']);
  });

  testWidgets('as setas trocam o mês; não há mês depois do de hoje, e o '
      'mês vazio aponta o caminho de volta', (tester) async {
    await _openEntries(tester);

    await _tap(tester, find.bySemanticsLabel('Próximo mês'));
    _expectListed(_september, hidden: ['Açougue do Zé']);

    await _tap(tester, find.bySemanticsLabel('Mês anterior'));
    _expectListed(['Açougue do Zé'], hidden: _september);
    expect(find.text('agosto de 2026'), findsWidgets);

    await _tap(tester, find.bySemanticsLabel('Mês anterior'));
    expect(find.text('Nada lançado em julho de 2026'), findsOneWidget);

    await _tap(tester, find.text('Voltar para setembro'));
    _expectListed(_september, hidden: ['Açougue do Zé']);
  });
}
