import 'package:design_system/design_system.dart';
import 'package:design_system/src/components/gauge/water_jar_painter.dart';
import 'package:design_system/src/components/gauge/water_motion.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

const _rs = 'R\$${BrlFormatter.nbsp}';
const _label = 'Pode gastar esta semana';
const _caption = r'de R$ 400,00 · até domingo';

Widget _gauge({
  double fraction = 0.53,
  int cents = 21200,
  CajuiTilt? tilt,
  CajuiThemeData? theme,
  double textScale = 1,
}) {
  return host(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: SizedBox(
        width: 360,
        child: CajuiWaterGauge(
          fraction: fraction,
          cents: cents,
          label: _label,
          caption: _caption,
          tilt: tilt,
        ),
      ),
    ),
    theme: theme,
  );
}

/// Avança [seconds] segundos em quadros de 60 por segundo: a física dá
/// passos curtos, e um salto só de cinco segundos valeria um quadro.
Future<void> _frames(WidgetTester tester, double seconds) async {
  for (var i = 0; i < seconds * 60; i++) {
    await tester.pump(const Duration(microseconds: 16667));
  }
}

WaterMotion _water(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(CajuiWaterGauge),
      matching: find.byType(CustomPaint),
    ),
  );
  return (paint.painter! as WaterJarPainter).water;
}

void main() {
  final reduced = CajuiThemeData.light(motionLevel: MotionLevel.reduced);

  group('CajuiWaterGauge', () {
    testWidgets('RNF-A11Y-20 o pote nunca vem sem o número em texto', (
      tester,
    ) async {
      await tester.pumpWidget(_gauge());
      await tester.pumpAndSettle();

      final node = tester.getSemantics(find.byType(CajuiWaterGauge));
      expect(node.label, _label);
      expect(node.value, '${_rs}212,00. $_caption');
      expect(find.text(_caption), findsOneWidget);
    });

    testWidgets('RNF-A11Y-08 a água enche, assenta e o relógio dorme', (
      tester,
    ) async {
      await tester.pumpWidget(_gauge());
      await tester.pump();

      expect(tester.hasRunningAnimations, isTrue);
      await _frames(tester, 5);
      expect(tester.hasRunningAnimations, isFalse);
      expect(_water(tester).level, closeTo(0.53, 0.001));
    });

    testWidgets('a inclinação balança a água, que volta a assentar', (
      tester,
    ) async {
      final tilt = ValueNotifier(Offset.zero);
      addTearDown(tilt.dispose);
      await tester.pumpWidget(_gauge(tilt: tilt));
      await tester.pumpAndSettle();

      tilt.value = const Offset(0.4, 0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(_water(tester).angle, lessThan(0));
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets(
      'RNF-A11Y-07 no movimento reduzido o pote é um desenho parado',
      (tester) async {
        final tilt = ValueNotifier(Offset.zero);
        addTearDown(tilt.dispose);
        await tester.pumpWidget(_gauge(tilt: tilt, theme: reduced));
        await tester.pump();

        expect(tester.hasRunningAnimations, isFalse);
        expect(_water(tester).level, 0.53);
        expect(find.text('${_rs}212,00'), findsOneWidget);

        tilt.value = const Offset(0.8, 0);
        await tester.pump();
        expect(tester.hasRunningAnimations, isFalse);
        expect(_water(tester).angle, 0);
      },
    );

    testWidgets('valor negativo: pote vazio e o tom da falta, sem alarme', (
      tester,
    ) async {
      final theme = CajuiThemeData.light();
      await tester.pumpWidget(_gauge(fraction: 0, cents: -2375));
      await tester.pumpAndSettle();

      final amount = tester.widget<CajuiAmountText>(
        find.byType(CajuiAmountText),
      );
      expect(amount.tone, CajuiAmountTone.shortfall);
      expect(theme.colors.shortfall, isNot(theme.colors.intent.danger));
      expect(_water(tester).level, 0);
    });

    testWidgets('RNF-A11Y-04 fonte a 200% em 360 de largura não corta nada', (
      tester,
    ) async {
      await tester.pumpWidget(_gauge(textScale: 2));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
