import 'package:cajui/src/core/feedback/sound_player_provider.dart';
import 'package:cajui/src/core/feedback/sound_settings_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Por onde saem o som e a vibração de cada toque, já obedecendo ao que a
/// pessoa escolheu nos ajustes.
final feedbackProvider = Provider<CajuiFeedback>((ref) {
  final feedback = SoundAndHapticFeedback(
    player: ref.watch(soundPlayerProvider),
  );
  ref.listen(
    soundSettingsProvider,
    (_, settings) => feedback.settings = settings,
    fireImmediately: true,
  );
  return feedback;
});
