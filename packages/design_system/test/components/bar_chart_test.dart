import 'package:design_system/design_system.dart';
import 'package:design_system/src/components/chart/bar_slot.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

const _rs = 'R\$${BrlFormatter.nbsp}';

/// Seis meses fictícios: dois em que faltou, quatro em que sobrou.
const _months = [
  CajuiChartBar(label: 'mai', title: 'Maio', cents: 18400, note: 'Sobrou'),
  CajuiChartBar(label: 'jun', title: 'Junho', cents: -9650, note: 'Faltou'),
  CajuiChartBar(label: 'jul', title: 'Julho', cents: 4200, note: 'Sobrou'),
  CajuiChartBar(label: 'ago', title: 'Agosto', cents: -2375, note: 'Faltou'),
  CajuiChartBar(label: 'set', title: 'Setembro', cents: 22110, note: 'Sobrou'),
  CajuiChartBar(label: 'out', title: 'Outubro', cents: 31200, note: 'Sobrou'),
];

Widget _chart({
  List<CajuiChartBar> bars = _months,
  double width = 328,
  CajuiThemeData? theme,
  ValueChanged<int>? onSelected,
}) {
  return host(
    SizedBox(
      width: width,
      child: CajuiBarChart(
        bars: bars,
        semanticLabel: 'Mês a mês: o que sobrou ou faltou',
        onSelected: onSelected,
      ),
    ),
    theme: theme,
  );
}

List<double> _growth(WidgetTester tester) => tester
    .widgetList<BarSlot>(find.byType(BarSlot))
    .map((slot) => slot.grow)
    .toList();

void main() {
  group('CajuiBarChart', () {
    testWidgets('RNF-A11Y-20 cada barra diz o mês e o valor por extenso', (
      tester,
    ) async {
      await tester.pumpWidget(_chart());
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Junho: faltou ${_rs}96,50'),
        findsOneWidget,
      );
      final latest = tester.getSemantics(
        find.bySemanticsLabel('Outubro: sobrou ${_rs}312,00'),
      );
      // Sem escolha, o destaque é o mês mais novo — e o leitor sabe disso.
      expect(latest, isSemantics(isSelected: true, isButton: true));
      expect(find.text('Outubro'), findsOneWidget);
    });

    testWidgets('um toque escolhe o mês e o destaque troca de valor', (
      tester,
    ) async {
      final chosen = <int>[];
      await tester.pumpWidget(_chart(onSelected: chosen.add));
      await tester.pumpAndSettle();

      await tester.tap(find.text('jun'));
      await tester.pumpAndSettle();

      expect(chosen, [1]);
      expect(find.text('Junho'), findsOneWidget);
      expect(find.text('Faltou'), findsOneWidget);
      expect(find.text('${_rs}96,50'), findsOneWidget);
    });

    testWidgets('a falta desce no tom neutro, nunca no vermelho', (
      tester,
    ) async {
      final theme = CajuiThemeData.light(shortfallStyle: ShortfallStyle.alarm);
      await tester.pumpWidget(_chart(theme: theme));
      await tester.pumpAndSettle();

      final colors = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(BarSlot),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => (box.decoration as BoxDecoration).color)
          .toSet();
      expect(colors, contains(theme.colors.data.fixed));
      expect(colors, contains(theme.colors.intent.positive));
      expect(colors, isNot(contains(theme.colors.intent.danger)));
    });

    testWidgets('com movimento, as barras crescem com mola: passam e voltam', (
      tester,
    ) async {
      await tester.pumpWidget(_chart());
      await tester.pump();
      var tallest = 0.0;
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        tallest = _growth(tester).fold(tallest, (a, b) => a > b ? a : b);
      }

      expect(tallest, greaterThan(1));
      await tester.pumpAndSettle();
      expect(_growth(tester), everyElement(1));
    });

    testWidgets('RNF-A11Y-07 no movimento reduzido as barras nascem prontas', (
      tester,
    ) async {
      final reduced = CajuiThemeData.light(motionLevel: MotionLevel.reduced);
      await tester.pumpWidget(_chart(theme: reduced));
      await tester.pump();

      expect(tester.hasRunningAnimations, isFalse);
      expect(_growth(tester), everyElement(1));
    });

    testWidgets(
      'RNF-A11Y-05 doze meses em tela estreita: rola, sem barra fina',
      (tester) async {
        final year = [
          for (var month = 1; month <= 12; month++)
            CajuiChartBar(
              label: 'm$month',
              title: 'Mês $month',
              cents: month.isEven ? month * 1000 : -month * 500,
              note: month.isEven ? 'Sobrou' : 'Faltou',
            ),
        ];
        await tester.pumpWidget(_chart(bars: year, width: 288));
        await tester.pumpAndSettle();

        expect(find.byType(SingleChildScrollView), findsOneWidget);
        // O mais novo aparece primeiro: a rolagem começa pelo fim.
        expect(find.text('m12').hitTestable(), findsOneWidget);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      },
    );
  });
}
