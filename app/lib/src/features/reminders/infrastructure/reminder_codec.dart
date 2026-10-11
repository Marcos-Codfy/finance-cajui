import 'package:cajui/src/features/reminders/application/reminder_routes.dart';
import 'package:domain/domain.dart';

/// O lembrete como o lado nativo o guarda: horários em milissegundos no
/// relógio do aparelho, textos prontos e a rota do toque.
///
/// O dia e a hora viram instante **aqui**, com o fuso do aparelho: é nele
/// que "9h" quer dizer alguma coisa para quem acorda (RN-1081).
abstract final class ReminderCodec {
  /// [reminder] pronto para atravessar o canal.
  static Map<String, Object?> encode(DueReminder reminder) => {
    'id': reminder.id,
    'eventKey': reminder.eventKey,
    'fireAt': _at(reminder.fireOn, hour: reminder.hour),
    // Fim do dia do vencimento: depois disso, nada chega (RN-840).
    'expiresAt': _at(reminder.dueOn.addDays(1)),
    'title': reminder.title,
    'text': reminder.text,
    'publicTitle': reminder.publicTitle,
    'publicText': reminder.publicText,
    'route': ReminderRoutes.of(reminder.target),
    'oncePerEvent': reminder.oncePerEvent,
  };

  static int _at(LocalDate day, {int hour = 0}) =>
      DateTime(day.year, day.month, day.day, hour).millisecondsSinceEpoch;
}
