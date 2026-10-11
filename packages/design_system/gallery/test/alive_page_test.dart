import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/src/app/gallery_app.dart';
import 'package:gallery/src/shell/gallery_destination.dart';

/// Tocador mudo que anota o que foi pedido.
class _MutePlayer implements SoundPlayer {
  final List<CajuiSound> played = [];

  @override
  Future<void> preload() async {}

  @override
  void play(CajuiSound sound, {required double volume, required double rate}) =>
      played.add(sound);

  @override
  Future<void> dispose() async {}
}

const _desktop = Size(1280, 1600);

/// O pote e as barras assentam sozinhos; o tempo fixo basta para a página
/// abrir sem esperar cada mola parar.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<_MutePlayer> _openAlive(WidgetTester tester) async {
  final player = _MutePlayer();
  tester.view.physicalSize = _desktop;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(GalleryApp(player: player));
  await tester.tap(find.text(GalleryDestination.alive.title).first);
  await _settle(tester);
  return player;
}

Future<void> _tapVisible(WidgetTester tester, String label) async {
  final target = find.text(label).first;
  await tester.ensureVisible(target);
  await _settle(tester);
  await tester.tap(target);
  await _settle(tester);
}

void main() {
  testWidgets('lançar toca a semente e desfazer, a folha — sem o toque', (
    tester,
  ) async {
    final player = await _openAlive(tester);
    await tester.tap(find.text('Som'));
    await _settle(tester);
    // Ligar o som já toca a chave subindo; o que interessa vem depois.
    player.played.clear();

    await _tapVisible(tester, 'Lançar');
    await _tapVisible(tester, 'Desfazer');

    expect(player.played, [CajuiSound.entrySaved, CajuiSound.undone]);
  });

  testWidgets('o número voa para o detalhe e volta sem erro', (tester) async {
    await _openAlive(tester);

    await _tapVisible(tester, 'Abrir o detalhe');
    await tester.pumpAndSettle();
    expect(find.text('Esta semana'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('Esta semana'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('o cartão vira com um toque, na própria gallery', (tester) async {
    await _openAlive(tester);
    final card = find.byType(CajuiCreditCard3D).at(1);
    await tester.ensureVisible(card);
    await _settle(tester);

    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(RegExp('^Limite do Cartão Ipê: em uso')),
      findsOneWidget,
    );
  });
}
