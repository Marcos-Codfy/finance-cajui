import 'package:cajui/src/features/reminders/application/reminder_schedule.dart';
import 'package:cajui/src/features/reminders/infrastructure/reminder_codec.dart';
import 'package:domain/domain.dart';
import 'package:flutter/services.dart';

/// Os lembretes de vencimento no Android, pelo canal `app.cajui/reminders`.
/// O lado nativo guarda a lista, marca o alarme do próximo e mostra cada um
/// no canal "Contas a vencer".
final class NativeReminderSchedule implements ReminderSchedule {
  /// Cria a porta. O canal entra por parâmetro para o teste simular o lado
  /// nativo.
  const new({this._channel = const MethodChannel('app.cajui/reminders')});

  final MethodChannel _channel;

  @override
  bool get isSupported => true;

  @override
  Future<void> replace(List<DueReminder> reminders) => _ask<void>('replace', {
    'items': [for (final reminder in reminders) ReminderCodec.encode(reminder)],
  });

  @override
  Future<bool> canPost() async => await _ask<bool>('canPost') ?? false;

  @override
  Future<void> allowPosting() => _ask<void>('allowPosting');

  /// Lembrete que não marca não pode derrubar o app: a lista volta inteira
  /// na próxima publicação.
  Future<T?> _ask<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
