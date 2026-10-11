import 'package:cajui/src/features/home/application/home_view.dart';
import 'package:cajui/src/features/home_widget/application/home_screen.dart';
import 'package:cajui/src/features/home_widget/application/home_snapshot.dart';
import 'package:cajui/src/features/home_widget/application/home_snapshot_provider.dart';
import 'package:cajui/src/features/home_widget/application/home_widget_providers.dart';
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

  test('RN-872 RN-1011 · com plano, o widget diz quanto dá para gastar na '
      'semana — o mesmo número do Início', () async {
    // O plano antigo lido como o novo: (3.200 − 1.200 de fixas − 362 de
    // parcelas) ÷ 4 = 409,50, e nada gasto ainda.
    final container = open(samplePlanEvents);
    final snapshot = await snapshotOf(container);

    expect(snapshot.label, 'Pode gastar esta semana');
    expect(snapshot.amount, _brl(40950));
    expect(
      snapshot.amount,
      MoneyFormat.brl(container.read(homeViewProvider)!.week.left),
    );
    expect(snapshot.caption, '${_brl(0)} de ${_brl(40950)} já gastos');
    expect(snapshot.validUntil, testToday, reason: 'o domingo fecha a semana');
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
