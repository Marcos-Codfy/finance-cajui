import 'package:cajui/src/core/settings/event_store_preferences.dart';
import 'package:cajui/src/core/settings/preferences_store.dart';
import 'package:cajui/src/core/storage/memory_event_store.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/reminders/application/due_reminders_provider.dart';
import 'package:cajui/src/features/reminders/application/reminders_providers.dart';
import 'package:cajui/src/features/reminders/application/reminders_switch.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persistence/event_store.dart';

import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';
import 'fake_reminder_schedule.dart';

String _brl(int cents) => MoneyFormat.brl(Money.fromCents(cents));

/// O aluguel de outubro, pago por Pix em [on].
LedgerEvent _rentPaid(LocalDate on) => EntryRecorded(
  Entry.create(
    id: 'rent-oct',
    description: 'Aluguel',
    amount: const Money.fromCents(110000),
    occurredOn: on,
    category: DefaultCatalog.emptyBook.categoryOf('rent'),
    paymentLines: [
      DefaultCatalog.paymentMethods.first.line(const Money.fromCents(110000)),
    ],
    today: on,
  ).valueOrNull!,
);

List<String> _moments(List<DueReminder> reminders) => [
  for (final reminder in reminders) '${reminder.eventKey} ${reminder.fireOn}',
];

void main() {
  late FakeReminderSchedule schedule;

  ProviderContainer open(
    List<LedgerEvent> events, {
    LocalDate? today,
    EventStore? preferences,
  }) {
    final container = ProviderContainer(
      overrides: [
        ...testOverrides(
          journal: MemoryLedgerJournal(events),
          today: today,
          preferences: preferences == null
              ? null
              : EventStorePreferences(preferences),
        ),
        reminderScheduleProvider.overrideWithValue(schedule),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> publish(ProviderContainer container) =>
      container.read(remindersPublisherProvider).publishFrom(container);

  setUp(() => schedule = FakeReminderSchedule());

  test('RN-840 RN-1081 · o aparelho recebe o aluguel e a internet de '
      'outubro, dois dias antes e no dia', () async {
    await publish(open(samplePlanEvents));

    final sent = schedule.replaced.single;
    expect(_moments(sent), [
      'bills:f-rent:2026-10-10 2026-10-08',
      'bills:f-rent:2026-10-10 2026-10-10',
      'bills:f-net:2026-10-15 2026-10-13',
      'bills:f-net:2026-10-15 2026-10-15',
    ]);
    expect(sent.first.title, 'Aluguel vence sábado, 10');
    // 3.200,00 − (1.200,00 de fixos + 1.060,00 de dia a dia + 362,00 de
    // parcelas) = 578,00 de sobra em outubro.
    expect(
      sent.first.text,
      '${_brl(110000)}. Pelo que está lançado, outubro continua com sobra '
      'de ${_brl(57800)} depois de pagar.',
    );
  });

  test('RN-1082 · o aluguel lançado sai da lista; a internet, que divide a '
      'categoria e vence depois, continua', () async {
    final today = LocalDate(2026, 10, 5);
    await publish(open([...samplePlanEvents, _rentPaid(today)], today: today));

    expect(_moments(schedule.replaced.single), [
      'bills:f-net:2026-10-15 2026-10-13',
      'bills:f-net:2026-10-15 2026-10-15',
    ]);
  });

  test('RN-1088 · com a chave desligada, o aparelho recebe a lista vazia e '
      'desmarca tudo', () async {
    final container = open(samplePlanEvents);
    await publish(container);

    container.read(remindersEnabledProvider.notifier).set(enabled: false);
    await publish(container);

    expect(schedule.replaced, hasLength(2));
    expect(schedule.replaced.first, isNotEmpty);
    expect(schedule.replaced.last, isEmpty);
  });

  test('RN-1088 · a chave nasce ligada, e desligada continua desligada na '
      'abertura seguinte', () async {
    final store = MemoryEventStore();
    final first = open(const [], preferences: store);
    expect(first.read(remindersEnabledProvider), isTrue);

    first.read(remindersEnabledProvider.notifier).set(enabled: false);
    await first.read(preferencesStoreProvider).update((current) => current);

    expect(
      open(const [], preferences: store).read(remindersEnabledProvider),
      isFalse,
    );
  });

  test('a mesma lista não atravessa o canal duas vezes, e o livro abrindo '
      'não publica nada', () async {
    final container = open(samplePlanEvents);
    final publisher = container.read(remindersPublisherProvider);

    await publisher.publish(null);
    await container.read(ledgerProvider.future);
    final reminders = container.read(dueRemindersProvider);
    await publisher.publish(reminders);
    await publisher.publish([...?reminders]);

    expect(schedule.replaced, hasLength(1));
  });
}
