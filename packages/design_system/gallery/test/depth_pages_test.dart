import 'package:design_system/design_system.dart';
import 'package:flutter/semantics.dart';
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

const _phone = Size(390, 844);

Future<void> _open(WidgetTester tester, GalleryDestination page) async {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(GalleryApp(player: _MutePlayer()));
  final chip = find.text(page.title).first;
  await tester.ensureVisible(chip);
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
}

void main() {
  testWidgets('o carrossel diz a página escolhida pelos pontos', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _open(tester, GalleryDestination.coverFlow);

    tester.semantics.performAction(
      find.semantics.byLabel('Números do mês'),
      SemanticsAction.increase,
    );
    await tester.pumpAndSettle();

    expect(find.text('Página 2 de 4 · O que entra'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a entrada roda de novo, e assenta', (tester) async {
    await _open(tester, GalleryDestination.cinematic);

    await _tapVisible(tester, find.text('Rodar de novo'));
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a carteira abre o maço de novo', (tester) async {
    await _open(tester, GalleryDestination.wallet);

    await _tapVisible(tester, find.text('Abrir o maço de novo'));
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpAndSettle();
    expect(find.byType(CajuiCreditCard3D), findsNWidgets(3));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('RNF-A11Y-07 trocar para o reduzido no meio não quebra nada', (
    tester,
  ) async {
    await _open(tester, GalleryDestination.depthScroll);
    final stage = find.byType(CajuiDepthScroll);
    await tester.ensureVisible(stage);
    await tester.pumpAndSettle();
    await tester.dragFrom(tester.getCenter(stage), const Offset(0, -300));
    await tester.pumpAndSettle();
    final scrolled = _depthOffset(tester);

    await _tapVisible(tester, find.text('Reduzido'));
    await tester.pumpAndSettle();

    // O nível caiu, e a tela não foi remontada: a rolagem ficou onde estava.
    expect(tester.takeException(), isNull);
    expect(scrolled, greaterThan(0));
    expect(_depthOffset(tester), scrolled);
  });
}

double _depthOffset(WidgetTester tester) => tester
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byType(CajuiDepthScroll),
            matching: find.byType(Scrollable),
          )
          .first,
    )
    .position
    .pixels;
