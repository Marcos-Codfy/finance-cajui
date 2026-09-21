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
      await _load(sound);
    }
  }

  /// Carrega um som, se ainda não estiver carregado, e devolve o tocador dele.
  Future<AudioPlayer> _load(CajuiSound sound) async {
    final loaded = _players[sound];
    if (loaded != null) return loaded;
    // O `audioplayers` prefixa `assets/` por conta própria, o que quebra
    // arquivo de pacote: a chave certa começa em `packages/`. Sem prefixo,
    // o caminho do token já é a chave inteira.
    final player = AudioPlayer(playerId: 'cajui_${sound.name}')
      ..audioCache = AudioCache(prefix: '');
    await player.setPlayerMode(PlayerMode.lowLatency);
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(AssetSource(sound.asset));
    return _players[sound] = player;
  }

  /// Som pedido antes do [preload] é carregado na hora: sai atrasado dessa
  /// vez e no tempo certo nas seguintes. É o que deixa o app não baixar som
  /// nenhum enquanto o som está desligado — que é como ele nasce.
  @override
  void play(CajuiSound sound, {required double volume, required double rate}) {
    // Falha de áudio nunca pode derrubar uma interação: som é reforço.
    Future<void>(() async {
      final player = await _load(sound);
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
