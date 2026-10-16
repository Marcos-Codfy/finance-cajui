import 'dart:async';
import 'dart:ui' show Offset;

import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// A inclinação do celular de quem visita a gallery, lida pelo navegador.
///
/// Até 15/10/2026 o cartão da gallery só inclinava com o arrasto: no celular,
/// o texto prometia "inclina com o celular" e nada acontecia. O app lê o
/// acelerômetro do Android; aqui é o do navegador, com a mesma conta
/// (`GravityTilt`). No computador, que não tem sensor, nada chega e o
/// arrasto continua valendo sozinho.
final class DeviceTilt {
  /// Começa a ouvir; cada leitura, já suavizada, vai para [onTilt].
  new(this.onTilt);

  /// Quem recebe a inclinação.
  final ValueChanged<Offset> onTilt;

  /// Quanto cada amostra puxa o valor: o sensor treme, o cartão não.
  static const double _smoothing = 0.15;

  StreamSubscription<AccelerometerEvent>? _subscription;
  Offset _smoothed = Offset.zero;

  /// Liga o sensor. Fora da web — o teste, a gallery no computador como app
  /// — não liga: não há plugin do outro lado para responder.
  void start() {
    if (!kIsWeb) return;
    _subscription ??= accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen(_heard, onError: (Object _) => stop());
  }

  void _heard(AccelerometerEvent event) {
    final reading = GravityTilt.of(x: event.x, y: event.y, z: event.z);
    _smoothed = Offset.lerp(_smoothed, reading, _smoothing)!;
    onTilt(_smoothed);
  }

  /// Desliga o sensor.
  void stop() {
    unawaited(_subscription?.cancel());
    _subscription = null;
  }
}
