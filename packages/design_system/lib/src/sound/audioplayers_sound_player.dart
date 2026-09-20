import 'package:audioplayers/audioplayers.dart';
import 'package:design_system/src/sound/cajui_sound.dart';
import 'package:design_system/src/sound/sound_player.dart';

/// O tocador de som sobre o pacote `audioplayers`.
///
/// Mantém um tocador por som, já carregado e em modo de baixa latência: um
/// toque seguido de outro não espera o anterior terminar, e nada é lido do
/// disco na hora de tocar.
///
/// Na web, o navegador só libera áudio depois de um gesto do usuário. Como
/// cada som do Cajui responde a um gesto, isso se resolve sozinho — mas o
/// primeiro som da sessão pode se perder, e o design aceita isso.
class AudioplayersSoundPlayer implements SoundPlayer {
  final Map<CajuiSound, AudioPlayer> _players = {};

  @override
  Future<void> preload() async {
    for (final sound in CajuiSound.values) {
      final player = AudioPlayer(playerId: 'cajui_${sound.name}');
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSource(AssetSource(_relative(sound.asset)));
      _players[sound] = player;
    }
  }

  /// O `audioplayers` já prefixa `assets/`; o caminho do token inclui o
  /// pacote, então aqui ele é ajustado ao que a biblioteca espera.
  String _relative(String asset) => asset.replaceFirst('assets/', '');

  @override
  void play(CajuiSound sound, {required double volume, required double rate}) {
    final player = _players[sound];
    if (player == null) return;
    // Falha de áudio nunca pode derrubar uma interação: som é reforço.
    Future<void>(() async {
      await player.stop();
      await player.setVolume(volume);
      await player.setPlaybackRate(rate);
      await player.resume();
    }).ignore();
  }

  @override
  Future<void> dispose() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
  }
}
