import 'package:domain/domain.dart';

/// O relógio de verdade, no **fuso de negócio**.
///
/// "Hoje" é o dia de quem usa o app, não o do servidor: a VM roda em UTC, e
/// sem isto um lançamento feito às 22h em Brasília cairia no dia seguinte — e
/// uma compra de "hoje" seria recusada como futura. O Brasil não tem horário
/// de verão desde 2019, então um deslocamento fixo basta.
final class SystemClock implements Clock {
  /// Cria o relógio com o deslocamento [offset] em relação a UTC.
  const new({this.offset = const Duration(hours: -3)});

  /// O deslocamento do fuso de negócio. Brasília: −3 horas.
  final Duration offset;

  @override
  DateTime now() => DateTime.now().toUtc();

  @override
  LocalDate today() =>
      LocalDate.fromDateTime(DateTime.now().toUtc().add(offset));
}
