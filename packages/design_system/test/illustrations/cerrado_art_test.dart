import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:design_system/src/illustrations/cerrado_painter.dart';
import 'package:design_system/src/illustrations/cerrado_palette.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

CerradoPainter _painterOf(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byType(CajuiCerradoArt),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter!
        as CerradoPainter;

void main() {
  final light = CerradoPalette.of(CajuiThemeData.light().colors);

  group('CajuiCerradoArt', () {
    for (final kind in CajuiCerrado.values) {
      testWidgets('${kind.name}: desenha no tamanho pedido, no claro e no '
          'escuro', (tester) async {
        for (final theme in [CajuiThemeData.light(), CajuiThemeData.dark()]) {
          await tester.pumpWidget(
            host(CajuiCerradoArt(kind, size: 96), theme: theme),
          );

          expect(tester.takeException(), isNull);
          expect(
            tester.getSize(find.byType(CajuiCerradoArt)),
            const Size.square(96),
          );
          expect(_painterOf(tester).kind, kind);
        }
      });
    }

    testWidgets('RNF-A11Y-07 · com movimento reduzido fica parada, de pé', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const CajuiCerradoArt(CajuiCerrado.ipe),
          theme: CajuiThemeData.light(motionLevel: MotionLevel.reduced),
        ),
      );

      // Se o balanço estivesse rodando, isto estouraria o tempo.
      await tester.pumpAndSettle();

      expect(tester.hasRunningAnimations, isFalse);
      expect(_painterOf(tester).sway, 0);
    });

    testWidgets('no nível leve também fica parada: o balanço é enfeite', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const CajuiCerradoArt(CajuiCerrado.leaf),
          theme: CajuiThemeData.light(motionLevel: MotionLevel.lite),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(tester.hasRunningAnimations, isFalse);
      expect(_painterOf(tester).sway, 0);
    });

    testWidgets('no nível completo balança devagar: um quarto do ciclo é o '
        'ponto mais inclinado', (tester) async {
      await tester.pumpWidget(host(const CajuiCerradoArt(CajuiCerrado.leaf)));
      await tester.pump(CajuiDurations.breeze ~/ 4);

      expect(tester.hasRunningAnimations, isTrue);
      expect(_painterOf(tester).sway, closeTo(1, 0.01));
    });

    testWidgets('é decorativa por padrão; com descrição, o leitor de tela a '
        'lê como imagem', (tester) async {
      await tester.pumpWidget(host(const CajuiCerradoArt(CajuiCerrado.ipe)));
      expect(find.bySemanticsLabel('Ipê em flor'), findsNothing);

      await tester.pumpWidget(
        host(
          const CajuiCerradoArt(CajuiCerrado.ipe, semanticLabel: 'Ipê em flor'),
        ),
      );
      expect(find.bySemanticsLabel('Ipê em flor'), findsOneWidget);
    });
  });

  group('CerradoPainter', () {
    test('pinta as três, paradas e no extremo do balanço, sem erro', () {
      for (final kind in CajuiCerrado.values) {
        for (final sway in const [-1.0, 0.0, 1.0]) {
          final recorder = ui.PictureRecorder();
          CerradoPainter(
            kind: kind,
            palette: light,
            sway: sway,
          ).paint(Canvas(recorder), const Size.square(128));
          recorder.endRecording().dispose();
        }
      }
    });

    test('só repinta quando o desenho, o balanço ou o tema mudam', () {
      final dark = CerradoPalette.of(CajuiThemeData.dark().colors);
      CerradoPainter painter({
        CajuiCerrado kind = CajuiCerrado.cashew,
        double sway = 0,
        CerradoPalette? palette,
      }) => CerradoPainter(kind: kind, palette: palette ?? light, sway: sway);

      expect(painter().shouldRepaint(painter()), isFalse);
      expect(painter(sway: 0.5).shouldRepaint(painter()), isTrue);
      expect(painter(kind: CajuiCerrado.ipe).shouldRepaint(painter()), isTrue);
      expect(painter(palette: dark).shouldRepaint(painter()), isTrue);
    });

    test('as cores vêm dos tokens do tema: no escuro, a folha é a vereda '
        'clara e o disco some no fundo da noite', () {
      final dark = CerradoPalette.of(CajuiThemeData.dark().colors);

      expect(light.leaf, CajuiThemeData.light().colors.intent.positive);
      expect(dark.leaf, CajuiThemeData.dark().colors.intent.positive);
      expect(dark.leaf, isNot(light.leaf));
      expect(dark.backdrop, CajuiThemeData.dark().colors.surface.sunken);
    });
  });
}
