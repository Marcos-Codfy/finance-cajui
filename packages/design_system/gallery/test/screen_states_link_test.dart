import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/src/pages/screens/shared/screen_state_page.dart';
import 'package:gallery/src/pages/screens/shared/variant_slug.dart';
import 'package:gallery/src/shell/gallery_destination.dart';
import 'package:gallery/src/shell/gallery_pages.dart';

import 'support/gallery_harness.dart';

/// O estado escolhido no seletor da tela aberta.
String _openState(WidgetTester tester) => tester
    .widgetList<CajuiChip>(
      find.descendant(
        of: find.byKey(ScreenStatePage.selectorKey),
        matching: find.byType(CajuiChip),
      ),
    )
    .singleWhere((chip) => chip.selected)
    .label;

void main() {
  test('todo destino do menu tem página', () {
    for (final page in GalleryDestination.values) {
      expect(galleryHasPage(page), isTrue, reason: page.title);
    }
  });

  test('o nome do estado vira pedaço de endereço sem acento nem espaço', () {
    expect(variantSlug('Sem rede'), 'sem-rede');
    expect(
      variantSlug('Mês no verde, primeira vez'),
      'mes-no-verde-primeira-vez',
    );
    expect(variantSlug('IA fora do ar'), 'ia-fora-do-ar');
  });

  testWidgets('a vitrine de estados abre a tela grande já no estado tocado', (
    tester,
  ) async {
    await openGallery(tester, page: GalleryDestination.screenStates);

    await tapVisible(tester, find.bySemanticsLabel('Início: Sem rede. Abrir'));

    expect(find.text(GalleryDestination.home.title), findsWidgets);
    expect(_openState(tester), 'Sem rede');
  });

  testWidgets('o link com o estado abre a tela nele', (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        '/inicio?estado=sem-rede';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );

    await openGallery(tester);

    expect(_openState(tester), 'Sem rede');
  });

  testWidgets('estado desconhecido no link abre a tela no estado de sempre', (
    tester,
  ) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        '/comprovante?estado=nao-existe';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );

    await openGallery(tester);

    expect(_openState(tester), 'Confirmando');
  });
}
