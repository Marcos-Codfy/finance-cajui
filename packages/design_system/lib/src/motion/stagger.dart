import 'package:design_system/src/tokens/primitives/cajui_durations.dart';

/// A partir deste bloco, todos chegam juntos com o último: uma cascata não
/// pode ficar esperando a lista inteira.
const int maxStaggered = 5;

double _fraction(Duration part) =>
    part.inMicroseconds / CajuiDurations.slowest.inMicroseconds;

/// O quanto o bloco [index] de uma cascata já fez da própria chegada,
/// quando a cascata inteira está em [progress], de 0 a 1.
///
/// Cada bloco começa `CajuiDurations.stagger` depois do anterior, e todos
/// terminam dentro de `CajuiDurations.slowest`: a cascata inteira cabe no
/// teto de 600 ms do projeto, qualquer que seja o tamanho da lista.
double staggered(double progress, int index) {
  final start = _fraction(CajuiDurations.stagger * index.clamp(0, maxStaggered));
  final span = 1 - _fraction(CajuiDurations.stagger * maxStaggered);
  return ((progress - start) / span).clamp(0.0, 1.0);
}
