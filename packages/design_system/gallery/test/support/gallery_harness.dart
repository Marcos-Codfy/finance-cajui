import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/src/app/gallery_app.dart';
import 'package:gallery/src/pages/screens/shared/phone_frame.dart';
import 'package:gallery/src/pages/screens/shared/screen_state_page.dart';
import 'package:gallery/src/shell/gallery_destination.dart';

/// Tocador mudo que anota o que foi pedido: o teste não tem áudio, mas
/// precisa saber que som cada toque pediu.
class MutePlayer implements SoundPlayer {
  /// Os sons pedidos, na ordem.
  final List<CajuiSound> played = [];

  @override
  Future<void> preload() async {}

  @override
  void play(CajuiSound sound, {required double volume, required double rate}) =>
      played.add(sound);

  @override
  Future<void> dispose() async {}
}

/// Uma janela de computador. O menu pode passar da altura dela: [goTo] rola
/// até o item antes de tocar.
const desktop = Size(1280, 1600);

/// Algumas páginas têm animação em laço (carregando, esqueleto), então
/// esperar "até parar" nunca termina: avança-se um tempo fixo.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// Abre a gallery em [size] e, se dado, vai até [page].
Future<MutePlayer> openGallery(
  WidgetTester tester, {
  Size size = desktop,
  GalleryDestination? page,
}) async {
  final player = MutePlayer();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(GalleryApp(player: player));
  await settle(tester);
  if (page != null) await goTo(tester, page);
  return player;
}

/// Vai até [page] pelo menu.
Future<void> goTo(WidgetTester tester, GalleryDestination page) async {
  final item = find.text(page.title).first;
  await tester.ensureVisible(item);
  await tester.tap(item);
  await settle(tester);
}

/// Rola até [target] aparecer e toca nele.
Future<void> tapVisible(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await settle(tester);
  await tester.tap(target);
  await settle(tester);
}

/// Os nomes dos estados no seletor da tela aberta — só os do seletor, e não
/// os chips que a própria tela mostra.
List<String> variantLabels(WidgetTester tester) => tester
    .widgetList<CajuiChip>(
      find.descendant(
        of: find.byKey(ScreenStatePage.selectorKey),
        matching: find.byType(CajuiChip),
      ),
    )
    .map((chip) => chip.label)
    .toList();

/// Escolhe o estado [label] no seletor.
Future<void> pickVariant(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(ScreenStatePage.selectorKey),
      matching: find.widgetWithText(CajuiChip, label),
    ),
  );
  await settle(tester);
}

/// A rolagem vertical da tela dentro do aparelho.
Finder phoneScroll() => find
    .descendant(
      of: find.byType(PhoneFrame),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    )
    .first;

/// O texto [text] montado na árvore, à vista ou não.
///
/// Na fonte de teste cada letra é um quadrado, e a fala comprida ocupa o
/// dobro da altura de verdade: o que no aparelho estaria à vista fica
/// abaixo da borda, montado mas fora da tela.
Finder anywhere(String text) => find.text(text, skipOffstage: false);

/// O chip [label], à vista ou não.
Finder chipAnywhere(String label) => find.ancestor(
  of: anywhere(label),
  matching: find.byType(CajuiChip, skipOffstage: false),
);

/// Rola a tela do aparelho até [target] ser montado e aparecer.
Future<void> scrollPhoneTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 120, scrollable: phoneScroll());
  await settle(tester);
}

/// Os textos da árvore inteira: o dos `Text`, o dos `RichText`, o dos
/// campos e o que o leitor de tela ouve — rótulo de medidor também conta.
List<String> treeTexts(WidgetTester tester) => [
  for (final widget in tester.allWidgets)
    ...switch (widget) {
      Text(:final data?) => [data],
      Text(:final textSpan?) => [textSpan.toPlainText()],
      RichText(:final text) => [text.toPlainText()],
      EditableText(:final controller) => [controller.text],
      Semantics(:final properties) => [
        ?properties.label,
        ?properties.value,
        ?properties.hint,
      ],
      _ => const <String>[],
    },
];
