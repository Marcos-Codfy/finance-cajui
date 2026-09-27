import 'package:domain/domain.dart';

/// Um relógio parado em 20 de setembro de 2026, o dia do cenário.
final class FixedClock implements Clock {
  /// Cria o relógio parado.
  const new();

  @override
  LocalDate today() => LocalDate(2026, 9, 20);

  @override
  DateTime now() => DateTime.utc(2026, 9, 20, 12);
}
