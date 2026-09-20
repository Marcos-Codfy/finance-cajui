import 'package:design_system/src/sound/cajui_sound.dart';

/// Quem de fato toca um som.
///
/// É uma porta: o design system decide **qual** som e **quando**; a
/// implementação decide **como**. Isso deixa trocar o motor de áudio — a
/// escolha final depende de medir latência em aparelho real (ADR-016) — sem
/// tocar em nenhum componente, e deixa os testes sem áudio de verdade.
abstract interface class SoundPlayer {
  /// Carrega os sons em memória. Som atrasado em relação ao toque é pior que
  /// nenhum som; por isso nada é lido do disco na hora de tocar.
  Future<void> preload();

  /// Toca [sound] com [volume] de 0 a 1 e velocidade [rate], em que 1 é o
  /// tom original.
  void play(CajuiSound sound, {required double volume, required double rate});

  /// Libera os recursos de áudio.
  Future<void> dispose();
}
