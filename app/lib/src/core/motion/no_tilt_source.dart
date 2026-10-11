import 'package:cajui/src/core/motion/tilt_source.dart';

/// Nenhuma inclinação: a web, o teste e o aparelho sem sensor.
final class NoTiltSource implements TiltSource {
  /// Cria a fonte vazia.
  const new();

  @override
  TiltReading? open() => null;
}
