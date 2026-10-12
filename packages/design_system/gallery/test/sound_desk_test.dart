import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/src/shell/gallery_destination.dart';

import 'support/gallery_harness.dart';

void main() {
  testWidgets('cada família de controle toca o seu som, com o som ligado', (
    tester,
  ) async {
    final player = await openGallery(
      tester,
      page: GalleryDestination.soundDesk,
    );
    await tester.tap(find.text('Som nas interações'));
    await settle(tester);
    // Ligar o som já toca a chave subindo; o que interessa vem depois.
    player.played.clear();

    await tapVisible(tester, find.text('Salvar lançamento'));
    await tapVisible(tester, find.text('Sobra de outubro'));
    await tester.enterText(find.byType(EditableText), 'a');
    await settle(tester);
    await tapVisible(tester, find.widgetWithText(CajuiChip, 'Mercado'));

    expect(player.played, [
      CajuiSound.tap,
      CajuiSound.card,
      CajuiSound.key,
      CajuiSound.toggleOn,
    ]);
  });

  testWidgets('com o som desligado, as famílias de toque ficam mudas', (
    tester,
  ) async {
    final player = await openGallery(
      tester,
      page: GalleryDestination.soundDesk,
    );

    await tapVisible(tester, find.text('Salvar lançamento'));
    await tapVisible(tester, find.widgetWithText(CajuiChip, 'Mercado'));

    expect(player.played, isEmpty);
  });
}
