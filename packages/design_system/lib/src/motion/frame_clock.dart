import 'package:flutter/scheduler.dart';

/// Pede quadros só enquanto alguma coisa ainda se mexe.
///
/// A água e o cartão reagem ao sensor, que não tem hora para parar. Um
/// relógio ligado o tempo todo gastaria bateria a 60 quadros por segundo com
/// a tela parada; este acorda quando chega um empurrão e dorme sozinho quando
/// [onFrame] diz que tudo assentou.
class FrameClock {
  /// Cria o relógio. [onFrame] recebe os segundos desde o quadro anterior e
  /// devolve se ainda há movimento.
  new({required TickerProvider vsync, required this.onFrame}) {
    _ticker = vsync.createTicker(_tick);
  }

  /// Avança o movimento e diz se ele continua.
  final bool Function(double seconds) onFrame;

  late final Ticker _ticker;
  Duration _last = Duration.zero;

  /// Se o relógio está pedindo quadros.
  bool get isRunning => _ticker.isActive;

  /// Acorda o relógio, se ele estiver dormindo.
  void wake() {
    if (_ticker.isActive) return;
    _last = Duration.zero;
    _ticker.start();
  }

  /// Para de pedir quadros, mesmo com movimento pendente.
  void sleep() => _ticker.stop();

  void _tick(Duration elapsed) {
    final seconds =
        (elapsed - _last).inMicroseconds / Duration.microsecondsPerSecond;
    _last = elapsed;
    if (!onFrame(seconds)) _ticker.stop();
  }

  /// Libera o relógio.
  void dispose() => _ticker.dispose();
}
