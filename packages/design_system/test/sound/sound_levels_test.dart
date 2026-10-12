import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';

/// Quanto do som sobra no alto-falante do celular: o trecho mais alto de
/// 30 ms, só acima de 400 Hz, em dBFS. Abaixo disso o alto-falante quase
/// não toca — e era ali que estavam o clique do botão e a nota do aviso.
double _heardDb(List<double> samples) {
  final heard = _highPass(samples, 400);
  final size = min(heard.length, (44100 * 0.03).round());
  var sum = 0.0;
  for (var n = 0; n < size; n++) {
    sum += heard[n] * heard[n];
  }
  var loudest = sum;
  for (var n = size; n < heard.length; n++) {
    sum += heard[n] * heard[n] - heard[n - size] * heard[n - size];
    loudest = max(loudest, sum);
  }
  return 10 * log(loudest / size) / ln10;
}

/// Passa-alta de segunda ordem (RBJ, Butterworth), como o da ferramenta de
/// masterização (`tool/sound/level_sounds.py`).
List<double> _highPass(List<double> samples, double cutoff) {
  final w0 = 2 * pi * cutoff / 44100;
  final alpha = sin(w0) / sqrt2;
  final a0 = 1 + alpha;
  final b0 = (1 + cos(w0)) / 2 / a0;
  final b1 = -(1 + cos(w0)) / a0;
  final a1 = -2 * cos(w0) / a0;
  final a2 = (1 - alpha) / a0;
  final out = List<double>.filled(samples.length, 0);
  var (x1, x2, y1, y2) = (0.0, 0.0, 0.0, 0.0);
  for (var n = 0; n < samples.length; n++) {
    final x = samples[n];
    final y = b0 * x + b1 * x1 + b0 * x2 - a1 * y1 - a2 * y2;
    (x2, x1, y2, y1) = (x1, x, y1, y);
    out[n] = y;
  }
  return out;
}

/// As amostras do arquivo do token, de −1 a 1, depois do cabeçalho de 44
/// bytes.
List<double> _samples(CajuiSound sound) {
  final bytes = File(sound.asset.replaceFirst('packages/design_system/', ''))
      .readAsBytesSync()
      .buffer
      .asByteData();
  return [
    for (var at = 44; at + 1 < bytes.lengthInBytes; at += 2)
      bytes.getInt16(at, Endian.little) / 32768,
  ];
}

void main() {
  group('Som que se ouve no celular (pedido do dono em 12/10)', () {
    test('todo arquivo bate perto do teto, sem colar nele: a reamostragem do '
        'aparelho estala no que encosta em 0 dBFS', () {
      for (final sound in CajuiSound.values) {
        final peak = _samples(sound).map((s) => s.abs()).reduce(max);
        final db = 20 * log(peak) / ln10;

        expect(db, inInclusiveRange(-1.5, -0.5), reason: sound.asset);
      }
    });

    test('nenhum som some no alto-falante: a tecla, que soa a cada letra, '
        'pode ficar atrás; os outros, não', () {
      // Antes da masterização: tecla −23,8; card −15,9; botão −14,3; aviso
      // −12,3. Era preciso pôr o volume no máximo para ouvir.
      for (final sound in CajuiSound.values) {
        final floor = sound == CajuiSound.key ? -15.0 : -12.0;

        expect(
          _heardDb(_samples(sound)),
          greaterThanOrEqualTo(floor),
          reason: sound.asset,
        );
      }
    });
  });
}
