import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/reminders/application/due_reminders_provider.dart';
import 'package:cajui/src/features/reminders/application/reminder_schedule.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Leva os lembretes de vencimento ao aparelho (RN-1081).
///
/// O livro muda a cada lançamento, e quase sempre a lista fica igual — um
/// gasto no mercado não paga o aluguel. Só a lista que mudou atravessa o
/// canal: cada publicação reescreve o que o aparelho guarda e remarca o
/// alarme.
class RemindersPublisher {
  /// Cria o publicador sobre [_schedule].
  new(this._schedule);

  final ReminderSchedule _schedule;
  List<DueReminder>? _last;

  /// Publica [reminders], se a lista mudou desde a última vez. `null` — o
  /// livro ainda abrindo — não publica nada.
  Future<void> publish(List<DueReminder>? reminders) async {
    if (reminders == null || listEquals(reminders, _last)) return;
    _last = reminders;
    await _schedule.replace(reminders);
  }

  /// Publica a lista em vigor em [container]: é o que o motor de segundo
  /// plano faz depois de lançar, com o app fechado — a conta paga pelo
  /// aviso do banco deixa de ser lembrada sem esperar o app abrir.
  Future<void> publishFrom(ProviderContainer container) async {
    await container.read(ledgerProvider.future);
    await publish(container.read(dueRemindersProvider));
  }
}
