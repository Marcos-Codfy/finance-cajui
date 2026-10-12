import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/src/app/gallery_route_parser.dart';
import 'package:gallery/src/pages/screens/overview/screen_thumbnail.dart';
import 'package:gallery/src/shell/gallery_destination.dart';
import 'package:gallery/src/shell/gallery_nav.dart';
import 'package:gallery/src/shell/gallery_panel.dart';

import 'support/gallery_harness.dart';

/// Os endereços que a gallery mandou ao navegador, com o "substituir".
List<({String uri, bool replace})> _watchAddress(WidgetTester tester) {
  final reports = <({String uri, bool replace})>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.navigation,
    (call) async {
      if (call.method == 'routeInformationUpdated') {
        final args = call.arguments as Map<Object?, Object?>;
        reports.add((
          uri: args['uri']! as String,
          replace: args['replace']! as bool,
        ));
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.navigation,
      null,
    ),
  );
  return reports;
}

void _openAt(WidgetTester tester, String address) {
  tester.binding.platformDispatcher.defaultRouteNameTestValue = address;
  addTearDown(tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);
}

void main() {
  test('estado que não existe na página não fica no endereço', () {
    for (final address in ['/inicio?estado=nao-existe', '/cores?estado=x']) {
      expect(
        GalleryRouteParser.locationOf(Uri.parse(address)).state,
        isNull,
        reason: address,
      );
    }
  });

  testWidgets('o endereço sem página é corrigido no lugar, sem empilhar: o '
      'primeiro Voltar sai da gallery', (tester) async {
    final reports = _watchAddress(tester);
    await openGallery(tester);

    expect(reports.first, (uri: '/visao-geral', replace: true));
  });

  testWidgets('trocar de página empilha; trocar de estado substitui', (
    tester,
  ) async {
    final reports = _watchAddress(tester);
    await openGallery(tester, page: GalleryDestination.home);
    expect(reports.last, (uri: '/inicio', replace: false));

    await pickVariant(tester, 'Sem rede');
    expect(reports.last, (uri: '/inicio?estado=sem-rede', replace: true));
  });

  testWidgets('aberto pelo teclado, o painel recebe o foco, fecha no Esc e '
      'devolve o foco ao botão', (tester) async {
    await openGallery(tester);
    final button = Focus.of(tester.element(find.text('Ajustes')))
      ..requestFocus();
    await settle(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);
    expect(find.byType(GalleryPanel), findsOneWidget);
    final focused = FocusManager.instance.primaryFocus!.context!;
    expect(
      find.ancestor(
        of: find.byWidget(focused.widget),
        matching: find.byType(GalleryPanel),
      ),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    expect(find.byType(GalleryPanel), findsNothing);
    expect(button.hasFocus, isTrue);
  });

  testWidgets('o Tab pula de miniatura em miniatura, sem entrar nos botões '
      'de dentro', (tester) async {
    await openGallery(tester, page: GalleryDestination.screenStates);
    final thumbnails = find.byType(ScreenThumbnail);
    Focus.of(
      tester.element(
        find.descendant(of: thumbnails.first, matching: find.byType(Text)).last,
      ),
    ).requestFocus();
    await settle(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await settle(tester);

    final focused = FocusManager.instance.primaryFocus!.context!;
    final owner = focused.findAncestorWidgetOfExactType<ScreenThumbnail>();
    expect(owner, tester.widget<ScreenThumbnail>(thumbnails.at(1)));
  });

  testWidgets('aberto por um link, o menu rola até a página aberta', (
    tester,
  ) async {
    _openAt(tester, '/icones');
    await openGallery(tester, size: const Size(1280, 800));

    final menu = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(GalleryNav),
        matching: find.byType(Scrollable),
      ),
    );
    expect(menu.position.pixels, greaterThan(0));
    final item = find.descendant(
      of: find.byType(GalleryNav),
      matching: find.text(GalleryDestination.icons.title),
    );
    expect(tester.getRect(item).bottom, lessThan(800));
  });

  testWidgets('o painel de páginas fecha se a página muda por fora', (
    tester,
  ) async {
    await openGallery(tester, size: const Size(390, 844));
    await tester.tap(find.widgetWithText(CajuiButton, 'Páginas'));
    await settle(tester);
    expect(find.byType(GalleryPanel), findsOneWidget);

    // O Voltar do navegador chega como um endereço novo.
    await tester.binding.handlePushRoute('/cores');
    await settle(tester);

    expect(find.byType(GalleryPanel), findsNothing);
  });
}
