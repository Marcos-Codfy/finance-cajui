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

  test('RN-872 · com faixas no plano, o widget diz quanto dá para gastar na '
      'semana — o mesmo número do painel', () async {
    // Variável em dinheiro de 410,00; a semana de 14 a 20 de setembro tem 7
    // dos 17 dias que restavam no mês: 410,00 × 7 ÷ 17 = 168,82 (RN-641).
    final snapshot = await snapshotOf(open(samplePlanEvents));

    expect(snapshot.label, 'Pode gastar esta semana');
    expect(snapshot.amount, _brl(16882));
    expect(snapshot.caption, '${_brl(0)} de ${_brl(16882)} já usados');
    expect(snapshot.validUntil, testToday, reason: 'o domingo fecha a semana');
  });

  test(
    'RN-872 · sem faixas no plano, o widget mostra o gasto do mês',
    () async {
      final snapshot = await snapshotOf(open(const []));

      expect(snapshot.label, 'Gasto do mês');
      expect(snapshot.amount, _brl(0));
      expect(snapshot.validUntil, LocalDate(2026, 9, 30));
    },
  );

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
