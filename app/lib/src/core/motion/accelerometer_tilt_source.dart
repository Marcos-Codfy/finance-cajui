import 'dart:async';
import 'dart:math' as math;

import 'package:cajui/src/core/motion/tilt_source.dart';
import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// A inclinação lida do acelerômetro do Android, no formato do design
/// system: `dx` é o lado, `dy` é frente e trás descontada a pose de quem
/// segura o celular (`CajuiTilt`).
final class AccelerometerTiltSource implements TiltSource {
  /// Cria a fonte.
  const new();

  @override
  TiltReading? open() {
    final reading = _Reading._();
    return (tilt: reading.tilt, close: reading.close);
  }
}

/// Uma leitura: segue o sensor com o app à vista e para quando ele some.
final class _Reading {
  new _() {
    _lifecycle = AppLifecycleListener(onHide: _pause, onShow: _resume);
    _resume();
  }

  /// A pose de repouso: o celular na mão fica a uns 40° da horizontal.
  static const double _restPitch = 40 * math.pi / 180;

  /// Quanto cada amostra puxa o valor: o sensor treme, e a água não pode
  /// tremer junto.
  static const double _smoothing = 0.15;

  static const double _gravity = 9.81;

  final ValueNotifier<Offset> tilt = ValueNotifier(Offset.zero);
  StreamSubscription<AccelerometerEvent>? _subscription;
  late final AppLifecycleListener _lifecycle;

  void _resume() {
    _subscription ??= accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen(_heard, onError: (Object _) => _pause());
  }

  void _pause() {
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  void _heard(AccelerometerEvent event) {
    tilt.value = Offset.lerp(tilt.value, _offsetOf(event), _smoothing)!;
  }

  void close() {
    _pause();
    _lifecycle.dispose();
    tilt.dispose();
  }

  /// O lado é o seno do giro; a frente, o quanto o topo veio na direção de
  /// quem segura, a partir da pose de repouso.
  static Offset _offsetOf(AccelerometerEvent event) {
    final side = (-event.x / _gravity).clamp(-1, 1).toDouble();
    final pitch = math.atan2(event.y, event.z);
    final front = math.sin(pitch - _restPitch).clamp(-1, 1).toDouble();
    return Offset(side, front);
  }
}
