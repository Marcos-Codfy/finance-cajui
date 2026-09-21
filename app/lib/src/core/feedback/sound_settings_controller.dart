import 'dart:async';

import 'package:cajui/src/core/feedback/sound_player_provider.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O que a pessoa escolheu sobre som e vibração.
///
/// O som nasce **desligado** e a vibração ligada: som inesperado em lugar
/// público constrange, e quem quer som liga com um toque.
class SoundSettingsController extends Notifier<SoundSettings> {
  @override
  SoundSettings build() => const SoundSettings();

  /// Liga ou desliga os sons.
  void setSound({required bool enabled}) {
    state = state.copyWith(soundEnabled: enabled);
    if (enabled) unawaited(_preload());
  }

  /// Liga ou desliga a vibração.
  void setHaptics({required bool enabled}) {
    state = state.copyWith(hapticsEnabled: enabled);
  }

  /// Os sons só são carregados quando o som é ligado: baixar dez arquivos
  /// para não tocar nenhum atrasaria a abertura à toa. E som é reforço — se
  /// o áudio não carregar, o app segue, só que mudo.
  Future<void> _preload() async {
    try {
      await ref.read(soundPlayerProvider).preload();
    } on Exception catch (error) {
      debugPrint('Sons indisponíveis: $error');
    }
  }
}

/// As escolhas de som e vibração em vigor.
final soundSettingsProvider =
    NotifierProvider<SoundSettingsController, SoundSettings>(
      SoundSettingsController.new,
    );
