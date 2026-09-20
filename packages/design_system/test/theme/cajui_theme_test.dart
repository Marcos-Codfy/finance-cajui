import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CajuiTypography', () {
    const typography = CajuiTypography();

    test('valores usam algarismos tabulares, para alinhar em coluna', () {
      const tabular = FontFeature.tabularFigures();

      expect(typography.amount.fontFeatures, contains(tabular));
      expect(typography.amountLarge.fontFeatures, contains(tabular));
      expect(typography.body.fontFeatures, isEmpty);
    });

    test('nenhum estilo fica abaixo de 12 px e o corpo tem 16 px', () {
      final styles = [
        typography.displayLarge,
        typography.displayMedium,
        typography.headline,
        typography.title,
        typography.body,
        typography.bodyStrong,
        typography.label,
        typography.caption,
        typography.overline,
        typography.amountLarge,
        typography.amount,
      ];

      expect(styles.every((style) => style.fontSize! >= 12), isTrue);
      expect(typography.body.fontSize, 16);
    });

    test('o corpo tem altura de linha de 1,5 (WCAG 1.4.12)', () {
      expect(typography.body.height, closeTo(1.5, 0.001));
    });

    test('a voz é Fraunces e o dado é Geist, e nenhum estilo fixa cor', () {
      expect(typography.displayLarge.fontFamily, contains('Fraunces'));
      expect(typography.body.fontFamily, contains('Geist'));
      expect(typography.displayLarge.color, isNull);
      expect(typography.body.color, isNull);
    });
  });

  group('CajuiThemeData', () {
    test('a falta do mês troca de cor num lugar só', () {
      final calm = CajuiThemeData.light();
      final alarm = CajuiThemeData.light(shortfallStyle: ShortfallStyle.alarm);

      expect(calm.colors.shortfall, calm.colors.intent.notice);
      expect(alarm.colors.shortfall, alarm.colors.intent.danger);
    });

    test('o tema escuro não é o claro invertido', () {
      final dark = CajuiThemeData.dark();

      expect(dark.colors.surface.base, isNot(const Color(0xFF000000)));
      expect(dark.colors.brightness, Brightness.dark);
    });
  });

  group('CajuiTheme', () {
    testWidgets('entrega o tema aos descendentes e avisa quando ele muda', (
      tester,
    ) async {
      final seen = <MotionLevel>[];
      Widget probe(CajuiThemeData data) => CajuiTheme(
        data: data,
        child: Builder(
          builder: (context) {
            seen.add(CajuiTheme.of(context).motionLevel);
            return const SizedBox.shrink();
          },
        ),
      );

      await tester.pumpWidget(probe(CajuiThemeData.light()));
      await tester.pumpWidget(
        probe(CajuiThemeData.light(motionLevel: MotionLevel.reduced)),
      );

      expect(seen, [MotionLevel.full, MotionLevel.reduced]);
    });
  });
}
