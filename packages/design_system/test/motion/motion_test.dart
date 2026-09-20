import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

void main() {
  group('MotionLevelResolver', () {
    MotionLevel resolve({
      MotionLevel preferred = MotionLevel.full,
      bool system = false,
      bool dropping = false,
    }) => MotionLevelResolver.resolve(
      preferred: preferred,
      systemReducesMotion: system,
      framesAreDropping: dropping,
    );

    test('o pedido do sistema por movimento reduzido vence tudo', () {
      expect(resolve(system: true), MotionLevel.reduced);
      expect(resolve(system: true, dropping: true), MotionLevel.reduced);
    });

    test('quadros caindo rebaixam para lite, nunca promovem', () {
      expect(resolve(dropping: true), MotionLevel.lite);
      expect(
        resolve(preferred: MotionLevel.reduced, dropping: true),
        MotionLevel.reduced,
      );
    });

    test('sem nada contra, vale a preferência', () {
      expect(resolve(), MotionLevel.full);
      expect(resolve(preferred: MotionLevel.lite), MotionLevel.lite);
    });
  });

  group('RNF-PERF-02 FrameBudgetWindow', () {
    const onTime = Duration(milliseconds: 12);
    const late = Duration(milliseconds: 24);

    test('janela incompleta nunca acusa', () {
      final window = FrameBudgetWindow();
      for (var i = 0; i < 100; i++) {
        window.record(late);
      }

      expect(window.isDropping, isFalse);
    });

    test('5% de quadros atrasados é tolerado; 6%, não', () {
      FrameBudgetWindow filled(int lateFrames) {
        final window = FrameBudgetWindow(size: 100);
        for (var i = 0; i < 100; i++) {
          window.record(i < lateFrames ? late : onTime);
        }
        return window;
      }

      expect(filled(5).isDropping, isFalse);
      expect(filled(6).isDropping, isTrue);
    });
  });

  group('FrameBudgetMonitor', () {
    test('avisa uma vez e não volta atrás na mesma sessão', () {
      final monitor = FrameBudgetMonitor(window: FrameBudgetWindow(size: 10));
      var notifications = 0;
      monitor.addListener(() => notifications++);

      for (var i = 0; i < 10; i++) {
        monitor.record(const Duration(milliseconds: 30));
      }
      for (var i = 0; i < 50; i++) {
        monitor.record(const Duration(milliseconds: 8));
      }

      expect(monitor.framesAreDropping, isTrue);
      expect(notifications, 1);
      monitor.dispose();
    });
  });

  group('efeitos da marca', () {
    testWidgets('a contagem chega ao valor final e nunca passa dele', (
      tester,
    ) async {
      final seen = <int>[];
      Widget counter(int value) => host(
        CajuiCountUp(
          value: value,
          builder: (context, cents) {
            seen.add(cents);
            return const SizedBox.shrink();
          },
        ),
      );

      await tester.pumpWidget(counter(0));
      await tester.pumpWidget(counter(10647));
      await tester.pumpAndSettle();

      expect(seen.last, 10647);
      expect(seen.every((cents) => cents <= 10647), isTrue);
    });

    testWidgets('no movimento reduzido o valor muda de uma vez', (
      tester,
    ) async {
      final seen = <int>{};
      final reduced = CajuiThemeData.light(motionLevel: MotionLevel.reduced);
      Widget counter(int value) => host(
        CajuiCountUp(
          value: value,
          builder: (context, cents) {
            seen.add(cents);
            return const SizedBox.shrink();
          },
        ),
        theme: reduced,
      );

      await tester.pumpWidget(counter(0));
      await tester.pumpWidget(counter(10647));
      await tester.pumpAndSettle();

      expect(seen, {0, 10647});
    });

    testWidgets('RNF-A11Y-08 a entrada roda uma vez e termina', (tester) async {
      await tester.pumpWidget(
        host(const CajuiEntrance(index: 3, child: Text('Mercado'))),
      );
      await tester.pumpAndSettle();

      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text('Mercado'), findsOneWidget);
    });
  });
}
