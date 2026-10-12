import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/src/pages/senses/sound_notes.dart';
import 'package:gallery/src/shell/gallery_destination.dart';
import 'package:gallery/src/shell/gallery_group.dart';

import 'support/gallery_harness.dart';

void main() {
  testWidgets('cada página abre sem erro, em tela larga', (tester) async {
    await openGallery(tester);

    for (final destination in GalleryDestination.values) {
      await goTo(tester, destination);

      expect(tester.takeException(), isNull, reason: destination.title);
    }
  });

  testWidgets('a gallery mostra TODOS os ícones do design system', (
    tester,
  ) async {
    // Guarda contra o defeito que a criou: por vinte ícones, a gallery não
    // mostrava nenhum. Gallery que mostra menos do que existe mente sobre o
    // que existe, e quem desenha a próxima tela não sabe o que já tem.
    await openGallery(tester, page: GalleryDestination.icons);

    for (final icon in CajuiIconData.values) {
      expect(find.text(icon.name), findsWidgets, reason: icon.name);
    }
  });

  testWidgets('cada página abre sem erro, em tela de celular', (tester) async {
    await openGallery(tester, size: const Size(390, 844));

    for (final destination in GalleryDestination.values) {
      await goTo(tester, destination);

      expect(tester.takeException(), isNull, reason: destination.title);
    }
  });

  testWidgets('cada estado de cada tela abre sem erro', (tester) async {
    await openGallery(tester);
    final screens = GalleryDestination.inGroup(GalleryGroup.screens);

    for (final destination in screens) {
      await goTo(tester, destination);
      // Só os chips do seletor: a tela também mostra chips — as sugestões
      // da Juju, as opções do extrato —, e eles somem ao trocar de estado.
      final labels = variantLabels(tester);

      expect(labels, isNotEmpty, reason: destination.title);
      for (final label in labels) {
        await pickVariant(tester, label);

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
    final player = await openGallery(
      tester,
      page: GalleryDestination.soundDesk,
    );

    await tapVisible(tester, find.text('Tocar').first);

    expect(player.played, [CajuiSound.tap]);
  });

  testWidgets('o chip de tema troca o tema da gallery inteira', (tester) async {
    await openGallery(tester);
    Brightness brightness() =>
        CajuiTheme.of(tester.element(find.text('Cajui'))).colors.brightness;

    expect(brightness(), Brightness.light);
    await tester.tap(find.text('Tema escuro'));
    await settle(tester);

    expect(brightness(), Brightness.dark);
  });

  testWidgets('RNF-A11Y-02 a página de contraste não mostra par reprovado', (
    tester,
  ) async {
    await openGallery(tester, page: GalleryDestination.contrast);

    expect(find.text('falha'), findsNothing);
    expect(find.textContaining('passam no nível AA'), findsOneWidget);
  });
}
