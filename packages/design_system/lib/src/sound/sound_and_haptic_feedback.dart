import 'dart:async';

import 'package:design_system/src/feedback/cajui_feedback.dart';
import 'package:design_system/src/sound/cajui_sound.dart';
import 'package:design_system/src/sound/sound_player.dart';
import 'package:design_system/src/sound/sound_settings.dart';
import 'package:flutter/services.dart';

/// A resposta de verdade: som e toque juntos, como um gesto só.
///
/// Cada evento dispara os dois canais ao mesmo tempo, e cada canal obedece à
/// sua preferência. O som nunca toca duas vezes igual: a velocidade varia um
/// pouco a cada disparo, porque repetição mecânica é o que transforma som
/// gostoso em irritante.
class SoundAndHapticFeedback implements CajuiFeedback {
  /// Cria a resposta com um tocador e as preferências [settings].
  new({required this._player, this.settings = const SoundSettings()});

  final SoundPlayer _player;
  int _plays = 0;

  /// As preferências em vigor. Trocar vale a partir do próximo evento.
  SoundSettings settings;

  /// Variações de velocidade, em ciclo: ±3% no máximo, o bastante para o
  /// ouvido não reconhecer o mesmo arquivo. É um ciclo fixo, e não sorteio,
  /// para o comportamento ser reproduzível em teste.
  static const _rates = [1.0, 0.975, 1.02, 0.99, 1.03, 0.985];

  void _sound(CajuiSound sound) {
    if (!settings.allows(sound.category)) return;
    final rate = _rates[_plays % _rates.length];
    _plays++;
    _player.play(sound, volume: settings.volume, rate: rate);
  }

  /// A vibração é disparada e esquecida: ninguém espera por ela, e uma falha
  /// do canal de plataforma não pode atrasar nem derrubar a interação.
  void _haptic(Future<void> Function() vibrate) {
    if (settings.hapticsEnabled) unawaited(vibrate());
  }

  /// O toque tem o peso de tecla de teclado, e não o do tique de rolagem.
  ///
  /// Era `selectionClick`, que no Android é o tique quase imperceptível de
  /// passar por uma opção numa roda. No aparelho, tocar um botão não se
  /// sentia. `lightImpact` é o mesmo pulso curto e seco que o teclado do
  /// telefone dá a cada tecla — presente sem ser um susto.
  @override
  void tap() {
    _sound(CajuiSound.tap);
    _haptic(HapticFeedback.lightImpact);
  }

  @override
  void toggle({required bool on}) {
    _sound(on ? CajuiSound.toggleOn : CajuiSound.toggleOff);
    _haptic(HapticFeedback.lightImpact);
  }

  @override
  void open() => _sound(CajuiSound.open);

  @override
  void saved() {
    _sound(CajuiSound.saved);
    _haptic(HapticFeedback.mediumImpact);
  }

  /// O aviso é macio nos dois canais: nota grave, e um pulso leve — nunca o
  /// padrão longo de erro do sistema.
  @override
  void notice() {
    _sound(CajuiSound.notice);
    _haptic(HapticFeedback.lightImpact);
  }

  @override
  void achievement() {
    _sound(CajuiSound.achievement);
    _haptic(HapticFeedback.mediumImpact);
  }

  /// Pulso de tecla, e não a confirmação média de [saved]: lançar se repete
  /// o dia inteiro, e um tranco a cada lançamento cansaria a mão.
  @override
  void entrySaved() {
    _sound(CajuiSound.entrySaved);
    _haptic(HapticFeedback.lightImpact);
  }

  /// Desfazer responde tão leve quanto lançar: é a mesma conversa, de volta.
  @override
  void undone() {
    _sound(CajuiSound.undone);
    _haptic(HapticFeedback.lightImpact);
  }
}
