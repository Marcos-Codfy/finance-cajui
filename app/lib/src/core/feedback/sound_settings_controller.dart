import 'dart:async';

import 'package:cajui/src/core/feedback/sound_player_provider.dart';
import 'package:cajui/src/core/settings/preferences_store.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O que a pessoa escolheu sobre som e vibração.
///
/// O som nasce **desligado** e a vibração ligada: som inesperado em lugar
/// público constrange, e quem quer som liga com um toque.
class SoundSettingsController extends Notifier<SoundSettings> {
  @override
  SoundSettings build() {
    final guardado = ref.read(preferencesStoreProvider).read();
    // Som ligado numa abertura anterior já vem com os arquivos a caminho:
    // esperar o primeiro toque para carregar atrasaria justamente o retorno
    // que a pessoa pediu.
    if (guardado.soundEnabled) unawaited(_preload());
    return SoundSettings(
      soundEnabled: guardado.soundEnabled,
      hapticsEnabled: guardado.hapticsEnabled,
    );
  }

  /// Liga ou desliga os sons.
  void setSound({required bool enabled}) {
    state = state.copyWith(soundEnabled: enabled);
    if (enabled) unawaited(_preload());
    _remember();
  }

  /// Liga ou desliga a vibração.
  void setHaptics({required bool enabled}) {
    state = state.copyWith(hapticsEnabled: enabled);
    _remember();
  }

  /// Guarda a escolha sem segurar a tela. Ela já mudou; o registro é o que
  /// faz ela continuar valendo amanhã.
  void _remember() {
    final escolhido = state;
    unawaited(
      ref
          .read(preferencesStoreProvider)
          .update(
            (atual) => atual.copyWith(
              soundEnabled: escolhido.soundEnabled,
              hapticsEnabled: escolhido.hapticsEnabled,
            ),
          ),
    );
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
