import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/src/app/gallery_app.dart';
import 'package:gallery/src/shell/gallery_destination.dart';

/// Tocador mudo: o teste não tem dispositivo de áudio.
class _MutePlayer implements SoundPlayer {
  @override
  Future<void> preload() async {}

  @override
  void play(CajuiSound sound, {required double volume, required double rate}) {}

  @override
  Future<void> dispose() async {}
}

/// Algumas páginas têm animação em laço (carregando, esqueleto), então
/// esperar "até parar" nunca termina: o teste avança um tempo fixo.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _open(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(GalleryApp(player: _MutePlayer()));
  await _settle(tester);
}

void main() {
  testWidgets('cada página abre sem erro, em tela larga', (tester) async {
    await _open(tester, const Size(1280, 900));

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

  testWidgets('o chip de tema troca o tema da gallery inteira', (tester) async {
    await _open(tester, const Size(1280, 900));
    Brightness brightness() => CajuiTheme.of(
      tester.element(find.text('Cajui')),
    ).colors.brightness;

    expect(brightness(), Brightness.light);
    await tester.tap(find.text('Tema escuro'));
    await _settle(tester);

    expect(brightness(), Brightness.dark);
  });

  testWidgets('RNF-A11Y-02 a página de contraste não mostra par reprovado', (
    tester,
  ) async {
    await _open(tester, const Size(1280, 900));
    await tester.tap(find.text('Contraste'));
    await _settle(tester);

    expect(find.text('falha'), findsNothing);
    expect(find.textContaining('passam no nível AA'), findsOneWidget);
  });
}
