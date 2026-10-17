import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/home_widget/application/widget_bill.dart';
import 'package:domain/domain.dart';

/// As contas a vencer do widget grande: as próximas de "Minhas contas" que
/// ainda não foram pagas, do vencimento mais cedo ao mais tarde.
///
/// Quem diz o que está em aberto é o domínio (`DueBills`, RN-1080 e
/// RN-1082) — a mesma resposta dos lembretes de vencimento, para o widget e
/// o lembrete nunca discordarem. Aqui só se escolhe a janela, a ordem e as
/// palavras.
abstract final class WidgetBills {
  /// Quantas cabem no widget grande sem apertar o número.
  static const limit = 3;

  /// Até onde se olha. Um mês à frente: no dia 28, as contas do começo do
  /// mês seguinte já aparecem, em vez de uma lista vazia.
  static const days = 30;

  /// As contas a vencer de [finances] a partir de [today]. As pagas num dos
  /// cartões de [cardIds] ficam de fora: quem vence é a fatura.
  static List<WidgetBill> upcoming(
    Finances finances, {
    required LocalDate today,
    Set<String> cardIds = const {},
  }) {
    final due = DueBills.within(
      DueWindow.from(today, days: days),
      finances,
      cardIds: cardIds,
    );
    return [
      for (final (_, bill) in _byDueDate(due).take(limit))
        WidgetBill(
          name: bill.name,
          dueOn: bill.dueOn,
          day: _day(bill.dueOn, today),
        ),
    ];
  }

  /// Do vencimento mais cedo ao mais tarde; no empate, a ordem em que o
  /// domínio respondeu, que é a do plano. O `sort` do Dart não promete
  /// manter a ordem dos empates, por isso o índice vai junto.
  static List<(int, DueItem)> _byDueDate(List<DueItem> due) =>
      [...due.indexed]..sort((a, b) {
        final byDay = a.$2.dueOn.compareTo(b.$2.dueOn);
        return byDay != 0 ? byDay : a.$1 - b.$1;
      });

  /// "vence dia 10" no mês corrente; do mês seguinte, com o mês junto, para
  /// o dia 3 de novembro não parecer o dia 3 que já passou.
  static String _day(LocalDate due, LocalDate today) =>
      due.budgetMonth == today.budgetMonth
      ? 'vence dia ${due.day}'
      : 'vence ${DateLabels.dayMonth(due)}';
}
