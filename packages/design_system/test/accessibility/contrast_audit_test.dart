import 'package:design_system/src/accessibility/contrast_audit.dart';
import 'package:design_system/src/accessibility/wcag_contrast.dart';
import 'package:design_system/src/tokens/semantic/cajui_colors.dart';
import 'package:design_system/src/tokens/semantic/shortfall_style.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WcagContrast', () {
    test('preto sobre branco dá 21:1 e uma cor sobre si mesma dá 1:1', () {
      const black = Color(0xFF000000);
      const white = Color(0xFFFFFFFF);

      expect(WcagContrast.ratio(black, white), closeTo(21, 0.01));
      expect(WcagContrast.ratio(white, white), closeTo(1, 0.0001));
    });

    test('reproduz os valores medidos na paleta da marca', () {
      const ink = Color(0xFF2A1D17);
      const sand = Color(0xFFFBF6EE);
      const cajui = Color(0xFFE4572E);

      expect(WcagContrast.ratio(ink, sand), closeTo(15.17, 0.01));
      expect(WcagContrast.ratio(cajui, sand), closeTo(3.42, 0.01));
    });
  });

  group('RNF-A11Y-02 todo par de cor usado junto cumpre a WCAG 2.2 AA', () {
    final themes = {
      'claro': const CajuiColors.light(),
      'escuro': const CajuiColors.dark(),
      'claro com falta em vermelho': const CajuiColors.light(
        shortfallStyle: ShortfallStyle.alarm,
      ),
      'escuro com falta em vermelho': const CajuiColors.dark(
        shortfallStyle: ShortfallStyle.alarm,
      ),
    };

    for (final MapEntry(key: name, value: colors) in themes.entries) {
      test('tema $name', () {
        final failures = ContrastAudit.pairsFor(
          colors,
        ).where((pair) => !pair.passes).map((pair) => pair.toString()).toList();

        expect(failures, isEmpty, reason: failures.join('\n'));
      });
    }
  });
}
