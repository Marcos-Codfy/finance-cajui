import 'package:cajui/src/features/home/application/home_view.dart';
import 'package:cajui/src/features/home_widget/application/home_screen.dart';
import 'package:cajui/src/features/home_widget/application/home_snapshot.dart';
import 'package:cajui/src/features/home_widget/application/home_snapshot_provider.dart';
import 'package:cajui/src/features/home_widget/application/home_widget_providers.dart';
import 'package:cajui/src/features/home_widget/application/widget_placement.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/review/application/review_providers.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';
import '../review/review_entries.dart';

final class _CountingScreen implements HomeScreen {
  final published = <HomeSnapshot>[];

  @override
  Future<void> publish(HomeSnapshot snapshot) async => published.add(snapshot);

  @override
  Future<WidgetPlacement> placement() async => WidgetPlacement.unavailable;

  @override
  Future<void> pin() async {}
}

String _brl(int cents) => MoneyFormat.brl(Money.fromCents(cents));

void main() {
  late _CountingScreen screen;

  ProviderContainer open(List<LedgerEvent> events) {
    final container = ProviderContainer(
      overrides: [
        ...testOverrides(journal: MemoryLedgerJournal(events)),
        homeScreenProvider.overrideWithValue(screen),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<HomeSnapshot> snapshotOf(ProviderContainer container) async {
    await container.read(ledgerProvider.future);
    await container.read(reviewedEntriesProvider.future);
    // Numa variável antes de devolver: no `return` de uma função assíncrona,
    // o tipo inferido para `read` vira `FutureOr`, e o Riverpod se perde.
    final snapshot = container.read(homeSnapshotProvider);
    return snapshot!;
  }

  setUp(() => screen = _CountingScreen());

  test('RN-872 · com plano, o widget diz a sobra do mês — o mesmo número do '
      'Início', () async {
    final container = open(samplePlanEvents);
    final snapshot = await snapshotOf(container);
    final budget = container.read(homeViewProvider)!.budget;

    expect(budget.closes, isTrue);
    expect(snapshot.label, 'Sobra de setembro');
    expect(snapshot.amount, MoneyFormat.brl(budget.result));
    expect(snapshot.caption, 'Depois de pagar tudo, pelo que está lançado.');
    expect(snapshot.validUntil, LocalDate(2026, 9, 30));
  });

  test('RN-843 · mês que não fecha não põe a falta na tela inicial: mostra o '
      'que sai do bolso e manda abrir o app', () async {
    final container = open([
      ...samplePlanEvents,
      EntryRecorded(reviewEntry('reforma', categoryId: 'home', cents: 900000)),
    ]);
    final snapshot = await snapshotOf(container);
    final budget = container.read(homeViewProvider)!.budget;

    expect(budget.closes, isFalse);
    expect(snapshot.label, 'Sai do bolso em setembro');
    expect(snapshot.amount, MoneyFormat.brl(budget.outOfPocket));
    expect(snapshot.amount, isNot(MoneyFormat.brl(budget.shortfall)));
    expect(snapshot.caption, contains('Abra o Cajui'));
  });

  test('RN-872 RN-1050 · sem plano, o widget mostra o que já saiu', () async {
    final snapshot = await snapshotOf(open(const []));

    expect(snapshot.label, 'Já saiu este mês');
    expect(snapshot.amount, _brl(0));
    expect(snapshot.validUntil, LocalDate(2026, 9, 30));
  });

  test(
    'RN-870 · o retrato leva o dia de cada gasto que espera revisão',
    () async {
      final snapshot = await snapshotOf(open(reviewWeek));

      expect(snapshot.reviewDates, [
        testToday.addDays(-1),
        testToday.addDays(-3),
      ]);
      expect(snapshot.toMap()['reviewDates'], ['2026-09-19', '2026-09-17']);
    },
  );

  test('o mesmo retrato não atravessa o canal duas vezes', () async {
    final container = open(const []);
    final snapshot = await snapshotOf(container);
    final publisher = container.read(homeSnapshotPublisherProvider);

    await publisher.publish(snapshot);
    await publisher.publish(snapshot);
    await publisher.publish(null);

    expect(screen.published, [snapshot]);
  });

  test(
    'em segundo plano, o retrato espera o livro e o revisto abrirem',
    () async {
      final container = open(reviewWeek);

      await container
          .read(homeSnapshotPublisherProvider)
          .publishFrom(container);

      expect(screen.published.single.reviewDates, hasLength(2));
    },
  );
}
