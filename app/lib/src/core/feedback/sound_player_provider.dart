import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O tocador de som do app. É um provider para o teste poder trocar o áudio
/// de verdade por um mudo.
final soundPlayerProvider = Provider<SoundPlayer>((ref) {
  final player = AudioplayersSoundPlayer();
  ref.onDispose(() => unawaited(player.dispose()));
  return player;
});
