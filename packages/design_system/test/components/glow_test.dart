import 'package:design_system/design_system.dart';
import 'package:design_system/src/components/glow/glow_painter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

const _closed = r'Setembro fechou com R$ 221,10 sobrando';

Widget _glow({
  required bool active,
  CajuiThemeData? theme,
  bool appear = false,
}) {
  return host(
    CajuiGlow(
      active: active,
      celebrateOnAppear: appear,
      child: const SizedBox(width: 280, height: 120, child: Text(_closed)),
    ),
    theme: theme,
  );
}

GlowPainter _painter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(CajuiGlow),
      matching: find.byType(CustomPaint),
    ),
  );
  return paint.painter! as GlowPainter;
}

void main() {
  group('CajuiGlow', () {
    testWidgets('RNF-A11Y-08 a festa roda uma vez quando a notícia vira boa', (
      tester,
    ) async {
      await tester.pumpWidget(_glow(active: false));
      await tester.pumpWidget(_glow(active: true));
      await tester.pump(const Duration(milliseconds: 100));

      expect(_painter(tester).bloom, isNotNull);
      await tester.pump(CajuiDurations.slowest);
      await tester.pump();

      // Assentou: a festa acabou, o halo calmo ficou.
      expect(tester.hasRunningAnimations, isFalse);
      expect(_painter(tester).bloom, isNull);
      expect(_painter(tester).presence, 1);
    });

    testWidgets('quando falta, nada acontece: sem halo, sem movimento', (
      tester,
    ) async {
      await tester.pumpWidget(_glow(active: false));
      await tester.pump();

      expect(tester.hasRunningAnimations, isFalse);
      expect(_painter(tester).presence, 0);
    });

    testWidgets('a festa ao abrir a tela só acontece quando pedida', (
      tester,
    ) async {
      await tester.pumpWidget(_glow(active: true));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_painter(tester).bloom, isNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_glow(active: true, appear: true));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_painter(tester).bloom, isNotNull);
      await tester.pumpAndSettle();
    });

    testWidgets('RNF-A11Y-07 no movimento reduzido o halo só aparece', (
      tester,
    ) async {
      final reduced = CajuiThemeData.light(motionLevel: MotionLevel.reduced);
      await tester.pumpWidget(_glow(active: false, theme: reduced));
      await tester.pumpWidget(_glow(active: true, theme: reduced));
      await tester.pump();

      expect(tester.hasRunningAnimations, isFalse);
      expect(_painter(tester).bloom, isNull);
      expect(_painter(tester).presence, 1);
    });

    testWidgets('o brilho é enfeite: o leitor de tela só ouve o bloco', (
      tester,
    ) async {
      await tester.pumpWidget(_glow(active: true, appear: true));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(_closed), findsOneWidget);
      expect(_painter(tester).semanticsBuilder, isNull);
    });

    test('a intensidade sobe na festa e assenta no halo calmo', () {
      expect(GlowPainter.intensityAt(null), 1);
      expect(GlowPainter.intensityAt(0.35), closeTo(1.8, 0.001));
      expect(GlowPainter.intensityAt(1), closeTo(1, 0.001));
    });
  });
}
