import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/src/app/gallery_route_parser.dart';
import 'package:gallery/src/app/gallery_router.dart';
import 'package:gallery/src/shell/gallery_destination.dart';
import 'package:gallery/src/shell/gallery_nav.dart';

import 'support/gallery_harness.dart';

const _phone = Size(390, 844);

void main() {
  group('endereço', () {
    test('cada página tem um endereço só seu, curto e sem acento', () {
      final slugs = GalleryDestination.values.map((page) => page.slug);
      expect(slugs.toSet(), hasLength(GalleryDestination.values.length));
      for (final slug in slugs) {
        expect(slug, matches(RegExp(r'^[a-z0-9-]+$')), reason: slug);
      }
    });

    test('o endereço abre a página, e a página volta ao mesmo endereço', () {
      for (final page in GalleryDestination.values) {
        final address = const GalleryRouteParser().restoreRouteInformation((
          page: page,
          state: null,
        ));
        final back = GalleryRouteParser.locationOf(address.uri);
        expect(back.page, page);
        expect(address.uri.path, '/${page.slug}');
      }
    });

    test('endereço vazio ou desconhecido abre a porta de entrada', () {
      for (final uri in [Uri.parse('/'), Uri.parse('/nao-existe')]) {
        expect(
          GalleryRouteParser.locationOf(uri).page,
          GalleryDestination.overview,
        );
      }
    });

    test('o estado de uma tela vai no endereço e volta dele', () {
      final location = GalleryRouteParser.locationOf(
        Uri.parse('/inicio?estado=sem-rede'),
      );
      expect(location.page, GalleryDestination.home);
      expect(location.state, 'sem-rede');
    });

    test('abrir uma página muda o endereço guardado', () {
      final router = GalleryRouter()..open(GalleryDestination.homeWidget);
      addTearDown(router.dispose);
      expect(router.currentConfiguration.page, GalleryDestination.homeWidget);
    });
  });

  testWidgets('a gallery abre na visão geral, e o atalho leva à página', (
    tester,
  ) async {
    await openGallery(tester);
    expect(find.text('Cajui · design system'), findsWidgets);

    await tapVisible(tester, find.bySemanticsLabel(RegExp('^Widget de vidro')));
    expect(find.text(GalleryDestination.homeWidget.title), findsWidgets);
    // Uma aurora por tamanho do widget: o grande e o pequeno.
    expect(find.byType(CajuiAurora), findsNWidgets(2));
  });

  testWidgets('no celular, "Páginas" abre o menu agrupado, e escolher fecha '
      'o menu e abre a página', (tester) async {
    await openGallery(tester, size: _phone);
    expect(find.byType(GalleryNav), findsNothing);

    await tester.tap(find.widgetWithText(CajuiButton, 'Páginas'));
    await settle(tester);
    expect(find.byType(GalleryNav), findsOneWidget);
    expect(find.text('COMPONENTES'), findsOneWidget);

    final item = find.descendant(
      of: find.byType(GalleryNav),
      matching: find.text(GalleryDestination.states.title),
    );
    await tester.ensureVisible(item);
    await tester.tap(item);
    await settle(tester);

    expect(find.byType(GalleryNav), findsNothing);
    expect(find.text(GalleryDestination.states.title), findsWidgets);
  });

  testWidgets('o menu do celular fecha pelo X sem trocar de página', (
    tester,
  ) async {
    await openGallery(tester, size: _phone);
    await tester.tap(find.widgetWithText(CajuiButton, 'Páginas'));
    await settle(tester);

    await tester.tap(find.bySemanticsLabel('Fechar Páginas'));
    await settle(tester);

    expect(find.byType(GalleryNav), findsNothing);
    expect(find.text('Cajui · design system'), findsWidgets);
  });

  testWidgets('os ajustes mudam o movimento da gallery inteira', (
    tester,
  ) async {
    await openGallery(tester, size: _phone);
    MotionLevel level() =>
        CajuiTheme.of(tester.element(find.text('Cajui · design system').first))
            .motionLevel;

    expect(level(), MotionLevel.full);
    await useSetting(tester, 'Reduzido');
    expect(level(), MotionLevel.reduced);
  });
}
