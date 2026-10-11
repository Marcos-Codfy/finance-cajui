import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/today_controller.dart';
import 'package:cajui/src/features/reminders/application/reminders_switch.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Os lembretes de vencimento que o aparelho deve ter marcados agora;
/// `null` enquanto o livro abre — publicar uma lista vazia nessa hora
/// desmarcaria tudo à toa.
///
/// **É o único lugar que diz de onde saem os lembretes.** Quem escreve e
/// decide é o domínio (RN-1080 a RN-1087); aqui só se junta o livro, os
/// cartões, o dia e a chave. Desligada, a lista é vazia (RN-1088).
final dueRemindersProvider = Provider<List<DueReminder>?>((ref) {
  final finances = ref.watch(financesProvider);
  final book = ref.watch(ledgerProvider).value;
  if (finances == null || book == null) return null;
  if (!ref.watch(remindersEnabledProvider)) return const [];
  return DueReminders.upcoming(
    finances,
    today: ref.watch(todayProvider),
    cards: book.cards,
    settlements: book.settlements,
  );
});
