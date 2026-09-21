import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/src/app/gallery_app.dart';
import 'package:gallery/src/pages/senses/sound_notes.dart';
import 'package:gallery/src/shell/gallery_destination.dart';
import 'package:gallery/src/shell/gallery_group.dart';

/// Tocador mudo: o teste não tem dispositivo de áudio.
class _MutePlayer implements SoundPlayer {
  @override
  Future<void> preload() async {}

  final List<CajuiSound> played = [];

  @override
  void play(CajuiSound sound, {required double volume, required double rate}) =>
      played.add(sound);

  @override
  Future<void> dispose() async {}
}

/// Algumas páginas têm animação em laço (carregando, esqueleto), então
/// esperar "até parar" nunca termina: o teste avança um tempo fixo.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// Alto o bastante para o menu lateral inteiro caber: a lista é preguiçosa e
/// não constrói o item que está fora da tela.
const _desktop = Size(1280, 1600);

Future<void> _open(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(GalleryApp(player: _MutePlayer()));
  await _settle(tester);
}

void main() {
  testWidgets('cada página abre sem erro, em tela larga', (tester) async {
    await _open(tester, _desktop);

    for (final destination in GalleryDestination.values) {
      await tester.tap(find.text(destination.title).first);
      await _settle(tester);

      expect(tester.takeException(), isNull, reason: destination.title);
    }
  });

  testWidgets('cada página abre sem erro, em tela de celular', (tester) async {
    await _open(tester, const Size(390, 844));

    for (final destination in GalleryDestination.values) {
      final chip = find.text(destination.title).first;
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await _settle(tester);

      expect(tester.takeException(), isNull, reason: destination.title);
    }
  });

  testWidgets('cada estado de cada tela abre sem erro', (tester) async {
    await _open(tester, _desktop);
    const global = {'Tema escuro', 'Som'};
    final screens = GalleryDestination.inGroup(GalleryGroup.screens);

    for (final destination in screens) {
      await tester.tap(find.text(destination.title).first);
      await _settle(tester);
      final labels = tester
          .widgetList<CajuiChip>(find.byType(CajuiChip))
          .map((chip) => chip.label)
          .where((label) => !global.contains(label))
          .toList();

      expect(labels, isNotEmpty, reason: destination.title);
      for (final label in labels) {
        await tester.tap(find.widgetWithText(CajuiChip, label));
        await _settle(tester);

        expect(
          tester.takeException(),
          isNull,
          reason: '${destination.title} · $label',
        );
      }
    }
  });

  test('todo som tem nota na mesa de som', () {
    expect(SoundNotes.all.keys.toSet(), CajuiSound.values.toSet());
  });

  testWidgets('a mesa de som toca o som pedido, mesmo com o som desligado', (
    tester,
  ) async {
    final player = _MutePlayer();
    tester.view.physicalSize = _desktop;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GalleryApp(player: player));
    await tester.tap(find.text('Mesa de som'));
    await _settle(tester);

    await tester.tap(find.text('Tocar').first);

    expect(player.played, [CajuiSound.tap]);
  });

  testWidgets('o chip de tema troca o tema da gallery inteira', (tester) async {
    await _open(tester, _desktop);
    Brightness brightness() =>
        CajuiTheme.of(tester.element(find.text('Cajui'))).colors.brightness;

    expect(brightness(), Brightness.light);
    await tester.tap(find.text('Tema escuro'));
    await _settle(tester);

    expect(brightness(), Brightness.dark);
  });

  testWidgets('RNF-A11Y-02 a página de contraste não mostra par reprovado', (
    tester,
  ) async {
    await _open(tester, _desktop);
    await tester.tap(find.text('Contraste'));
    await _settle(tester);

    expect(find.text('falha'), findsNothing);
    expect(find.textContaining('passam no nível AA'), findsOneWidget);
  });
}
