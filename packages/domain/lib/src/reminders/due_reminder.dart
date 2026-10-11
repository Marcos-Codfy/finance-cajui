import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/reminders/reminder_target.dart';
import 'package:meta/meta.dart';

/// Um lembrete de vencimento pronto para o aparelho marcar: quando chega, o
/// que diz com o celular desbloqueado, o que diz na tela bloqueada e que
/// tela abre (RN-840 a RN-849).
///
/// Sai do domínio já em texto — a voz do Cajui mora aqui (RN-802) — e o lado
/// nativo só guarda, marca e mostra.
@immutable
final class DueReminder {
  /// Cria o lembrete.
  const new({
    required this.id,
    required this.eventKey,
    required this.fireOn,
    required this.hour,
    required this.dueOn,
    required this.title,
    required this.text,
    required this.publicTitle,
    required this.publicText,
    required this.target,
    required this.oncePerEvent,
  });

  /// Único por vencimento e momento: o aparelho não mostra o mesmo duas
  /// vezes, mesmo que o app publique a lista de novo.
  final String id;

  /// O vencimento a que o lembrete pertence, o mesmo nos dois momentos.
  final String eventKey;

  /// O dia em que o lembrete chega.
  final LocalDate fireOn;

  /// A hora em que chega, no relógio do aparelho.
  final int hour;

  /// O dia do vencimento. Passado ele, o lembrete não chega mais (RN-840).
  final LocalDate dueOn;

  /// O título, com o celular desbloqueado: "Aluguel vence sábado, 10".
  final String title;

  /// O texto, com o valor e o efeito sobre o mês (RN-841, RN-842).
  final String text;

  /// O título na tela bloqueada, sem nome e sem valor (RN-843).
  final String publicTitle;

  /// O texto na tela bloqueada.
  final String publicText;

  /// A tela que o toque abre (RN-849).
  final ReminderTarget target;

  /// Se, depois de um aviso deste vencimento, o outro momento deve ficar em
  /// silêncio: é o mês com falta, em que nenhum aviso se repete (RN-846).
  final bool oncePerEvent;

  @override
  bool operator ==(Object other) =>
      other is DueReminder &&
      other.id == id &&
      other.fireOn == fireOn &&
      other.hour == hour &&
      other.title == title &&
      other.text == text &&
      other.publicTitle == publicTitle &&
      other.publicText == publicText &&
      other.target == target &&
      other.oncePerEvent == oncePerEvent;

  @override
  int get hashCode => Object.hash(
    id,
    fireOn,
    hour,
    title,
    text,
    publicTitle,
    publicText,
    target,
    oncePerEvent,
  );

  @override
  String toString() => 'DueReminder($id, $fireOn $hour h: $title)';
}
