import 'package:cajui/src/features/reminders/application/reminder_schedule.dart';
import 'package:domain/domain.dart';

/// Os alarmes do aparelho, de mentira: cada lista publicada fica guardada
/// para o teste conferir.
final class FakeReminderSchedule implements ReminderSchedule {
  /// As listas publicadas, na ordem.
  final replaced = <List<DueReminder>>[];

  /// Se o Android deixa o Cajui notificar.
  bool posting = true;

  /// Quantas vezes o app pediu para notificar.
  int asked = 0;

  @override
  bool get isSupported => true;

  @override
  Future<void> replace(List<DueReminder> reminders) async =>
      replaced.add(reminders);

  @override
  Future<bool> canPost() async => posting;

  @override
  Future<void> allowPosting() async => asked++;
}
