import 'package:design_system/design_system.dart';

/// Um tocador que não toca: anota o que pediram para os testes conferirem.
class MutePlayer implements SoundPlayer {
  /// Quantas vezes o carregamento dos sons foi pedido.
  int preloads = 0;

  /// Os sons que foram pedidos, na ordem.
  final List<CajuiSound> played = [];

  @override
  Future<void> preload() async => preloads++;

  @override
  void play(CajuiSound sound, {required double volume, required double rate}) {
    played.add(sound);
  }

  @override
  Future<void> dispose() async {}
}
