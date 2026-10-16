import 'dart:ui' show Offset;

/// O que faz o cartão seguir o celular de verdade.
///
/// A leitura crua da gravidade tem dois defeitos para um enfeite: ela muda
/// pouco — inclinar o celular 20° movia o cartão uns 4° — e depende de como
/// a pessoa segura o aparelho: deitado na mão, o cartão ficava torto e
/// parado (o que o dono viu em 15/10/2026). O filtro guarda a pose de quem
/// segura, que anda devagar, e mostra só o movimento em cima dela, com
/// ganho: o cartão reage a cada inclinação e volta ao centro sozinho.
final class TiltFilter {
  /// Cria o filtro na pose neutra.
  new();

  /// Quanto cada amostra puxa o valor: o sensor treme, o cartão não.
  static const double smoothing = 0.15;

  /// Quanto cada amostra puxa a pose de quem segura: a uns 15 por segundo,
  /// o cartão volta ao centro em uns três segundos parado.
  static const double settling = 0.02;

  /// O ganho do movimento: 20° de inclinação já levam o cartão ao máximo.
  static const double gain = 3;

  Offset? _pose;
  Offset _smoothed = Offset.zero;

  /// A inclinação do cartão para a leitura [raw] da gravidade
  /// (`GravityTilt.of`).
  Offset next(Offset raw) {
    final pose = _pose;
    if (pose == null) {
      // A primeira leitura é a pose: o cartão nasce reto.
      _pose = raw;
      _smoothed = raw;
      return Offset.zero;
    }
    _smoothed = Offset.lerp(_smoothed, raw, smoothing)!;
    final settled = Offset.lerp(pose, _smoothed, settling)!;
    _pose = settled;
    final moved = (_smoothed - settled) * gain;
    return Offset(
      moved.dx.clamp(-1, 1).toDouble(),
      moved.dy.clamp(-1, 1).toDouble(),
    );
  }
}
