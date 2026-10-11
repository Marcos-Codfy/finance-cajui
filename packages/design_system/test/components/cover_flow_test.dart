import 'package:design_system/design_system.dart';
import 'package:design_system/src/components/carousel/carousel_pose.dart';
import 'package:design_system/src/components/carousel/cover_flow_indicator.dart';
import 'package:design_system/src/components/carousel/cover_flow_slide.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

const _pages = ['Sobra do mês', 'Entra', 'Sai', 'Vale'];

Widget _flow({
  CajuiThemeData? theme,
  CajuiFeedback feedback = const SilentFeedback(),
  ValueChanged<int>? onPage,
  double textScale = 1,
  List<String> pages = _pages,
}) {
  return host(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: SizedBox(
        width: 360,
        child: CajuiCoverFlow(
          semanticLabel: 'Números do mês',
          onPageChanged: onPage,
          children: [
            for (final page in pages)
              CajuiCard(child: Text(page)),
          ],
        ),
      ),
    ),
    theme: theme,
    feedback: feedback,
  );
}

SemanticsNode _dots(WidgetTester tester) =>
    tester.getSemantics(find.byType(CoverFlowIndicator));

Rect _stage(WidgetTester tester) => tester.getRect(
  find
      .descendant(
        of: find.byType(CajuiCoverFlow),
        matching: find.byType(Stack),
      )
      .first,
);

void main() {
  group('CarouselPose', () {
    test('a página do centro fica de frente e inteira', () {
      final pose = CarouselPose.of(0, spacing: 240);

      expect(pose.isFlat, isTrue);
      expect(pose.opacity, 1);
    });

    test('a vizinha da direita gira com a borda de fora para longe', () {
      final pose = CarouselPose.of(1, spacing: 240);

      expect(pose.turn, CajuiDepth.carouselTurn);
      expect(pose.scale, closeTo(0.88, 1e-9));
      expect(pose.shift.dx, 240);
      expect(pose.opacity, closeTo(0.7, 1e-9));
    });

    test('a da esquerda gira para o outro lado', () {
      final pose = CarouselPose.of(-1, spacing: 240);

      expect(pose.turn, -CajuiDepth.carouselTurn);
      expect(pose.shift.dx, -240);
    });

    test('a segunda vizinha se esconde atrás da primeira', () {
      final pose = CarouselPose.of(2, spacing: 240);

      expect(pose.opacity, 0);
      // 240 × (1 + 0,55): mais perto da primeira do que a fila daria.
      expect(pose.shift.dx, closeTo(372, 1e-9));
    });

    test('RNF-A11Y-07 plana, a página só anda de lado', () {
      final pose = CarouselPose.of(1, spacing: 240, flat: true);

      expect(pose.turn, 0);
      expect(pose.scale, 1);
      expect(pose.opacity, 1);
      expect(pose.shift.dx, 240);
    });
  });

  group('CajuiCoverFlow', () {
    testWidgets('RNF-A11Y-06 cada página diz onde está, os pontos também', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_flow());

      // A posição vem antes do conteúdo: "Página 1 de 4, Sobra do mês".
      for (var i = 0; i < _pages.length; i++) {
        expect(
          find.bySemanticsLabel('Página ${i + 1} de 4\n${_pages[i]}'),
          findsOneWidget,
        );
      }
      expect(
        _dots(tester),
        isSemantics(
          label: 'Números do mês',
          value: 'Página 1 de 4',
          increasedValue: 'Página 2 de 4',
          isSlider: true,
          hasIncreaseAction: true,
          hasDecreaseAction: false,
        ),
      );
      semantics.dispose();
    });

    testWidgets('RNF-A11Y-10 ajustar os pontos troca a página sem arrastar', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final feedback = RecordingFeedback();
      final pages = <int>[];
      await tester.pumpWidget(_flow(feedback: feedback, onPage: pages.add));

      tester.semantics.performAction(
        find.semantics.byLabel('Números do mês'),
        SemanticsAction.increase,
      );
      await tester.pumpAndSettle();

      expect(pages, [1]);
      expect(feedback.calls, ['pageTurned']);
      expect(_dots(tester), isSemantics(value: 'Página 2 de 4'));
      semantics.dispose();
    });

    testWidgets('arrastar de lado encaixa na página seguinte', (tester) async {
      final feedback = RecordingFeedback();
      final pages = <int>[];
      await tester.pumpWidget(_flow(feedback: feedback, onPage: pages.add));

      await tester.drag(find.text('Sobra do mês'), const Offset(-160, 0));
      await tester.pumpAndSettle();

      expect(pages, [1]);
      expect(feedback.calls, ['pageTurned']);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('um gesto rápido passa uma página só', (tester) async {
      final pages = <int>[];
      await tester.pumpWidget(_flow(onPage: pages.add));

      await tester.fling(find.text('Sobra do mês'), const Offset(-300, 0), 4000);
      await tester.pumpAndSettle();

      expect(pages, [1]);
    });

    testWidgets('na primeira página, puxar para trás cede e volta', (
      tester,
    ) async {
      final pages = <int>[];
      await tester.pumpWidget(_flow(onPage: pages.add));

      await tester.drag(find.text('Sobra do mês'), const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(pages, isEmpty);
    });

    testWidgets('RNF-A11Y-10 tocar na vizinha a traz para o centro', (
      tester,
    ) async {
      final pages = <int>[];
      await tester.pumpWidget(_flow(onPage: pages.add));
      final stage = _stage(tester);

      await tester.tapAt(Offset(stage.right - 8, stage.center.dy));
      await tester.pumpAndSettle();

      expect(pages, [1]);
    });

    testWidgets('as setas do teclado trocam a página pelos pontos', (
      tester,
    ) async {
      final pages = <int>[];
      await tester.pumpWidget(_flow(onPage: pages.add));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(pages, [1]);
    });

    testWidgets('RNF-A11Y-07 no reduzido, nada gira e trocar é um corte', (
      tester,
    ) async {
      final pages = <int>[];
      await tester.pumpWidget(
        _flow(
          theme: CajuiThemeData.light(motionLevel: MotionLevel.reduced),
          onPage: pages.add,
        ),
      );
      await tester.drag(find.text('Sobra do mês'), const Offset(-160, 0));
      await tester.pump();

      for (final slide in tester.widgetList<Transform>(
        find.descendant(
          of: find.byType(CoverFlowSlide),
          matching: find.byType(Transform),
        ),
      )) {
        expect(slide.transform.entry(3, 2), 0);
      }
      expect(pages, [1]);
      // Só o esmaecer curto, e nenhuma mola: um quadro depois dos 120 ms,
      // nada mais se mexe.
      await tester.pump(CajuiDurations.reducedFade);
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('RNF-A11Y-04 cresce com a página mais alta, sem estourar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _flow(
          textScale: 2,
          pages: [
            'Sobra',
            'O que entra no mês, somando o salário e os extras do mês',
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final tallest = tester.getSize(find.byType(CajuiCard).last).height;
      expect(_stage(tester).height, greaterThanOrEqualTo(tallest));
    });

    testWidgets('RNF-A11Y-05 os pontos são alvo de toque de sobra', (
      tester,
    ) async {
      await tester.pumpWidget(_flow());

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  });
}
