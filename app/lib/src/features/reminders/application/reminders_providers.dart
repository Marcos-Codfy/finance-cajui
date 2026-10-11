import 'package:cajui/src/features/reminders/application/reminder_schedule.dart';
import 'package:cajui/src/features/reminders/application/reminders_publisher.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onde os lembretes ficam marcados. A raiz do app liga aos alarmes do
/// Android; sem ligação, eles não vão a lugar nenhum — é a web, e é o teste
/// que não fala de lembrete.
final reminderScheduleProvider = Provider<ReminderSchedule>(
  (ref) => const _Nowhere(),
);

/// Quem leva a lista até lá. Um por app: é ele que lembra a última.
final remindersPublisherProvider = Provider<RemindersPublisher>(
  (ref) => RemindersPublisher(ref.watch(reminderScheduleProvider)),
);

final class _Nowhere implements ReminderSchedule {
  const new();

  @override
  bool get isSupported => false;

  @override
  Future<void> replace(List<DueReminder> reminders) async {}

  @override
  Future<bool> canPost() async => false;

  @override
  Future<void> allowPosting() async {}
}
