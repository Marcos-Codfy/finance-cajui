import 'package:domain/domain.dart';

/// As datas do jeito que o guia de voz pede: por extenso e curtas, e
/// relativas quando estão perto — "hoje", "ontem", "sáb., 19 de set.".
abstract final class DateLabels {
  static const _weekdays = [
    'seg.',
    'ter.',
    'qua.',
    'qui.',
    'sex.',
    'sáb.',
    'dom.',
  ];

  static const _shortMonths = [
    'jan.', 'fev.', 'mar.', 'abr.', 'mai.', 'jun.', //
    'jul.', 'ago.', 'set.', 'out.', 'nov.', 'dez.',
  ];

  static const _months = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', //
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ];

  /// O dia [date] visto de [today]: relativo se for hoje ou ontem.
  static String day(LocalDate date, {required LocalDate today}) {
    return switch (date.daysUntil(today)) {
      0 => 'hoje',
      1 => 'ontem',
      _ => short(date),
    };
  }

  /// "sáb., 19 de set."
  static String short(LocalDate date) =>
      '${_weekdays[date.weekday - 1]}, ${date.day} de '
      '${_shortMonths[date.month - 1]}';

  /// "19 de set.": o dia sem o da semana, para onde falta lugar.
  static String dayMonth(LocalDate date) =>
      '${date.day} de ${_shortMonths[date.month - 1]}';

  /// "19 de setembro"
  static String long(LocalDate date) =>
      '${date.day} de ${_months[date.month - 1]}';

  /// "setembro de 2026"
  static String month(BudgetMonth month) =>
      '${_months[month.month - 1]} de ${month.year}';

  /// A hora de [moment] no fuso da casa, como se fala: "9h05", "14h32".
  static String time(DateTime moment) {
    final local = moment.toUtc().add(BusinessTime.offset);
    return '${local.hour}h${local.minute.toString().padLeft(2, '0')}';
  }

  /// Quando foi [moment], visto de [now], para "atualizado …": "às 14h32"
  /// no mesmo dia da casa, "ontem às 14h32" no anterior e "em 19 de set."
  /// antes disso. A hora sozinha engana quem abre o app no dia seguinte.
  static String when(DateTime moment, {required DateTime now}) {
    LocalDate dayOf(DateTime at) =>
        LocalDate.fromDateTime(at.toUtc().add(BusinessTime.offset));
    final day = dayOf(moment);
    return switch (day.daysUntil(dayOf(now))) {
      0 => 'às ${time(moment)}',
      1 => 'ontem às ${time(moment)}',
      _ => 'em ${dayMonth(day)}',
    };
  }
}
