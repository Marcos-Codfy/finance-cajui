import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart' show DefaultMaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/src/pages/screens/assistant/assistant_page.dart';
import 'package:gallery/src/pages/screens/capture/capture_page.dart';
import 'package:gallery/src/pages/screens/home/home_page.dart';
import 'package:gallery/src/pages/screens/overview/screen_catalog.dart';
import 'package:gallery/src/pages/screens/overview/screen_states_page.dart';
import 'package:gallery/src/pages/screens/overview/screen_thumbnail.dart';
import 'package:gallery/src/pages/screens/shared/phone_frame.dart';
import 'package:gallery/src/pages/screens/shared/screen_state_page.dart';
import 'package:gallery/src/shell/gallery_destination.dart';
import 'package:gallery/src/shell/gallery_section.dart';

import 'support/gallery_harness.dart';

const _phone = Size(390, 844);

/// Monta [page] sozinha, sem a casca da gallery. A vitrine não depende do
/// menu, e o teste dela também não.
Future<void> _mount(
  WidgetTester tester,
  Widget page, {
  Size size = desktop,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(page));
  await settle(tester);
}

/// O app mínimo em volta de [page]: o tema, o texto padrão e os textos que
/// o campo de texto pede, como a `GalleryApp` monta.
Widget _app(Widget page) {
  final theme = CajuiThemeData.light();
  return WidgetsApp(
    color: theme.colors.surface.base,
    localizationsDelegates: const [
      DefaultMaterialLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
    ],
    pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, _, _) => builder(context),
    ),
    builder: (context, child) => CajuiTheme(
      data: theme,
      child: DefaultTextStyle(
        style: theme.typography.body.copyWith(color: theme.colors.text.primary),
        child: child!,
      ),
    ),
    home: page,
  );
}

/// A miniatura do estado [state] da tela [screen], montada ou não.
Finder _thumbnail(String screen, String state) => find.byWidgetPredicate(
  (widget) =>
      widget is ScreenThumbnail &&
      widget.screen == screen &&
      widget.variant.label == state,
  skipOffstage: false,
);

/// A seção da tela [screen]. Pelo título da seção, e não pelo texto: o
/// nome de uma tela também aparece dentro das miniaturas de outra.
Finder _section(String screen) => find.byWidgetPredicate(
  (widget) => widget is GallerySection && widget.title == screen,
  skipOffstage: false,
);

/// A fileira de miniaturas da tela [screen]: a primeira lista de lado da
/// seção, antes das que existem dentro das telas.
Finder _row(String screen) => find
    .descendant(
      of: _section(screen),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is ListView && widget.scrollDirection == Axis.horizontal,
        skipOffstage: false,
      ),
    )
    .first;

/// A rolagem da fileira da tela [screen].
Finder _rowScroll(String screen) => find
    .descendant(
      of: _row(screen),
      matching: find.byType(Scrollable, skipOffstage: false),
    )
    .first;

/// O estado escolhido no seletor de chips.
String _selected(WidgetTester tester) => tester
    .widgetList<CajuiChip>(
      find.descendant(
        of: find.byKey(ScreenStatePage.selectorKey),
        matching: find.byType(CajuiChip),
      ),
    )
    .singleWhere((chip) => chip.selected)
    .label;

/// O texto [text] dentro da linha de estado da tela estreita.
Finder _inStepper(String text) => find.descendant(
  of: find.byKey(ScreenStatePage.stepperKey),
  matching: find.text(text),
);

Finder _stepButton(String label) => find.byWidgetPredicate(
  (widget) => widget is CajuiIconButton && widget.semanticLabel == label,
);

void main() {
  group('Estados das telas', () {
    test('cada tela da vitrine aponta para um destino do menu', () {
      final destinations = {
        for (final destination in GalleryDestination.values) destination.name,
      };

      expect(ScreenCatalog.screens.map((screen) => screen.id), [
        'home',
        'homeWidget',
        'capture',
        'statement',
        'closing',
        'debts',
        'assistant',
      ]);
      for (final screen in ScreenCatalog.screens) {
        expect(destinations, contains(screen.id));
      }
    });

    testWidgets('monta uma seção por tela, cada uma com os estados de '
        'variants()', (tester) async {
      await _mount(tester, ScreenStatesPage(onOpen: (_, _) {}));
      final sections = tester
          .widgetList<GallerySection>(
            find.byType(GallerySection, skipOffstage: false),
          )
          .toList();
      var total = 0;

      expect(
        sections.map((section) => section.title),
        ScreenCatalog.screens.map((screen) => screen.title),
      );
      for (final (index, screen) in ScreenCatalog.screens.indexed) {
        final count = screen.variants().length;
        total += count;
        final list = tester.widget<ListView>(_row(screen.title));

        expect(sections[index].description, '$count estados');
        expect(
          (list.childrenDelegate as SliverChildBuilderDelegate).childCount,
          count,
          reason: screen.title,
        );
      }
      expect(find.textContaining('nos $total estados'), findsOneWidget);
    });

    testWidgets('tocar numa miniatura chama onOpen com o id e o índice do '
        'estado', (tester) async {
      final opened = <(String, int)>[];
      await _mount(
        tester,
        ScreenStatesPage(onOpen: (id, index) => opened.add((id, index))),
      );

      expect(
        find.bySemanticsLabel('Início: Carregando. Abrir'),
        findsOneWidget,
      );
      await tapVisible(tester, _thumbnail(HomePage.title, 'Carregando'));
      await tapVisible(tester, _thumbnail(CapturePage.title, 'Confirmando'));
      // O último da Juju fica fora da vista: a fileira só o monta ao rolar
      // até ele.
      final last = _thumbnail(AssistantPage.title, 'Extrato lançado');
      expect(last, findsNothing);
      await tester.ensureVisible(_row(AssistantPage.title));
      await tester.scrollUntilVisible(
        last,
        300,
        scrollable: _rowScroll(AssistantPage.title),
      );
      await tapVisible(tester, last);

      expect(opened, [('home', 2), ('capture', 4), ('assistant', 12)]);
    });
  });

  group('Página de uma tela', () {
    testWidgets('initialIndex abre o estado pedido, e um pedido novo troca '
        'o estado', (tester) async {
      var index = 5;
      late StateSetter reopen;
      await _mount(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            reopen = setState;
            return HomePage(initialIndex: index);
          },
        ),
      );
      final labels = HomePage.variants().map((variant) => variant.label);

      expect(_selected(tester), labels.elementAt(5));
      expect(find.textContaining('6 de ${labels.length} · '), findsOneWidget);

      reopen(() => index = 3);
      await settle(tester);
      expect(_selected(tester), labels.elementAt(3));
    });

    testWidgets("o Comprovante abre em 'Confirmando', sem mudar a ordem do "
        'fluxo', (tester) async {
      await _mount(tester, const CapturePage());

      expect(_selected(tester), 'Confirmando');
      expect(variantLabels(tester).first, 'Fotografando');
    });

    testWidgets('em tela estreita, a linha de estado avança e volta, e os '
        'chips não aparecem', (tester) async {
      await _mount(tester, const HomePage(), size: _phone);
      final variants = HomePage.variants();
      final count = variants.length;

      expect(find.byKey(ScreenStatePage.selectorKey), findsNothing);
      expect(_inStepper(variants.first.label), findsOneWidget);
      expect(_inStepper('1 de $count'), findsOneWidget);

      await tester.tap(_stepButton('Próximo estado'));
      await settle(tester);
      expect(_inStepper(variants[1].label), findsOneWidget);
      expect(_inStepper('2 de $count'), findsOneWidget);

      await tester.tap(_stepButton('Estado anterior'));
      await settle(tester);
      await tester.tap(_stepButton('Estado anterior'));
      await settle(tester);
      // Antes do primeiro vem o último: a linha dá a volta.
      expect(_inStepper(variants.last.label), findsOneWidget);
      expect(_inStepper('$count de $count'), findsOneWidget);
    });

    testWidgets('em tela estreita, o aparelho vem logo abaixo da linha de '
        'estado, e a nota embaixo dele', (tester) async {
      await _mount(tester, const HomePage(), size: _phone);
      final stepper = tester.getRect(find.byKey(ScreenStatePage.stepperKey));
      final phone = tester.getRect(find.byType(PhoneFrame));
      final note = HomePage.variants().first.note;

      expect(phone.top - stepper.bottom, CajuiSpacing.lg);
      expect(phone.top, lessThan(_phone.height));
      expect(
        tester.getRect(find.text(note, skipOffstage: false)).top,
        greaterThan(phone.bottom),
      );
    });

    testWidgets('em tela larga, os chips e a nota ficam à direita do '
        'aparelho', (tester) async {
      await _mount(tester, const HomePage());
      final count = HomePage.variants().length;
      final phone = tester.getRect(find.byType(PhoneFrame));
      final chips = tester.getRect(find.byKey(ScreenStatePage.selectorKey));
      final note = tester.getRect(find.textContaining('1 de $count · '));

      expect(find.byKey(ScreenStatePage.stepperKey), findsNothing);
      expect(chips.left, greaterThan(phone.right));
      expect(note.left, greaterThan(phone.right));
      // Ao lado, e não embaixo: começam na altura do aparelho.
      expect(chips.top, lessThan(phone.bottom));
      expect(note.top, lessThan(phone.bottom));

      await pickVariant(tester, 'Primeiro uso');
      expect(find.textContaining('6 de $count · '), findsOneWidget);
    });
  });
}
