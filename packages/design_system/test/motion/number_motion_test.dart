import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

const _rs = 'R\$${BrlFormatter.nbsp}';

/// Um app de duas telas montado como o do Cajui: `WidgetsApp`, a superfície
/// no `builder` e a troca de tela da marca.
Widget _twoScreens(MotionLevel level) {
  final theme = CajuiThemeData.light(motionLevel: level);
  return WidgetsApp(
    color: theme.colors.surface.base,
    pageRouteBuilder: <T>(settings, builder) =>
        CajuiPageRoute<T>(settings: settings, builder: builder),
    builder: (context, child) => CajuiAppSurface(
      theme: theme,
      feedback: const SilentFeedback(),
      child: child!,
    ),
    home: Builder(
      builder: (context) => Column(
        children: [
          const CajuiHeroNumber(
            tag: 'week-left',
            child: CajuiAmountText(21200),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context)
                .push(CajuiPageRoute<void>(builder: (_) => const _Detail())),
            child: const Text('Abrir'),
          ),
        ],
      ),
    ),
  );
}

class _Detail extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => const Center(
    child: CajuiHeroNumber(
      tag: 'week-left',
      child: CajuiAmountText(21200, large: true),
    ),
  );
}

void main() {
  group('CajuiHeroNumber', () {
    testWidgets('o número do Início voa até a tela de detalhe', (tester) async {
      await tester.pumpWidget(_twoScreens(MotionLevel.full));

      await tester.tap(find.text('Abrir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      // A cópia que voa: os dois desenhos, esticados à caixa do voo.
      expect(find.byType(FittedBox), findsNWidgets(2));
      await tester.pumpAndSettle();
      expect(find.byType(FittedBox), findsNothing);
      expect(find.byType(_Detail), findsOneWidget);
    });

    testWidgets('RNF-A11Y-07 no movimento reduzido não há voo', (tester) async {
      await tester.pumpWidget(_twoScreens(MotionLevel.reduced));

      await tester.tap(find.text('Abrir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      expect(find.byType(FittedBox), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byType(_Detail), findsOneWidget);
    });
  });

  group('CajuiRollingAmount', () {
    testWidgets('rola desde o zero, e o leitor de tela só ouve o valor final', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const CajuiRollingAmount(21200, from: 0, large: true)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final transit = tester.widget<CajuiAmountText>(
        find.byType(CajuiAmountText),
      );
      expect(transit.cents, inExclusiveRange(0, 21200));
      expect(find.bySemanticsLabel('${_rs}212,00'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('${_rs}212,00'), findsOneWidget);
    });

    testWidgets('RNF-A11Y-07 no movimento reduzido o número nasce pronto', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const CajuiRollingAmount(21200, from: 0),
          theme: CajuiThemeData.light(motionLevel: MotionLevel.reduced),
        ),
      );

      expect(find.text('${_rs}212,00'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets(
      'sem ponto de partida, o número nasce pronto e só rola ao mudar',
      (tester) async {
        await tester.pumpWidget(host(const CajuiRollingAmount(21200)));
        expect(tester.hasRunningAnimations, isFalse);

        await tester.pumpWidget(host(const CajuiRollingAmount(18000)));
        await tester.pump(const Duration(milliseconds: 100));
        final transit = tester.widget<CajuiAmountText>(
          find.byType(CajuiAmountText),
        );
        expect(transit.cents, inExclusiveRange(18000, 21200));
        await tester.pumpAndSettle();
      },
    );
  });
}
