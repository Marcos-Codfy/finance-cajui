import 'package:design_system/design_system.dart';
import 'package:design_system/src/components/wallet/wallet_pose.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

const _screen = Size(360, 640);

/// Três cartões de 200 com 12 entre eles: lugares 0, 212 e 424.
WalletSlot _slot(int index) => (
  index: index,
  count: 3,
  top: index * 212.0,
  height: 200,
  lastTop: 424,
  gap: 12,
);

Widget _card(int index, {VoidCallback? onTap}) => GestureDetector(
  onTap: onTap,
  child: SizedBox(height: 200, child: Text('Cartão $index')),
);

/// A pilha numa lista que rola, abaixo de 100 de cabeçalho.
Widget _wallet({
  CajuiThemeData? theme,
  ScrollController? controller,
  double textScale = 1,
  ValueChanged<int>? onTap,
}) {
  return host(
    MediaQuery(
      data: MediaQueryData(
        size: _screen,
        textScaler: TextScaler.linear(textScale),
      ),
      child: SizedBox.fromSize(
        size: _screen,
        child: ListView(
          controller: controller,
          children: [
            const SizedBox(height: 100),
            _stack(onTap),
            const SizedBox(height: 1200),
          ],
        ),
      ),
    ),
    theme: theme,
  );
}

Widget _stack(ValueChanged<int>? onTap) => CajuiWalletStack(
  children: [for (var i = 0; i < 3; i++) _card(i, onTap: () => onTap?.call(i))],
);

Future<void> _screenSize(WidgetTester tester) async {
  tester.view.physicalSize = _screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

double _paintedTop(WidgetTester tester, int index) => tester
    .renderObject<RenderBox>(find.text('Cartão $index'))
    .localToGlobal(Offset.zero)
    .dy;

void main() {
  group('WalletPose', () {
    test('no maço, cada cartão está no lugar do primeiro, um pouco acima', () {
      final back = WalletPose.of(_slot(0), deal: 0);
      final front = WalletPose.of(_slot(2), deal: 0);

      // O de trás (dois à frente dele) aparece 16 px acima e 10% menor.
      expect(back.shift.dy, -16);
      expect(back.scale, closeTo(0.9, 1e-9));
      // O da frente, do lugar 424, sobe até o lugar 0, inteiro.
      expect(front.shift.dy, -424);
      expect(front.scale, 1);
    });

    test('aberto e fora de rolagem, o cartão fica parado e plano', () {
      final pose = WalletPose.of(_slot(1), deal: 1);

      expect(pose.isFlat, isTrue);
      expect(pose.alpha, 255);
    });

    test('rolando, o cartão para no alto e recua sob o seguinte', () {
      // O alto da tela está 300 abaixo do topo da pilha.
      final first = WalletPose.of(_slot(0), deal: 1, viewportTop: 300);
      final last = WalletPose.of(_slot(2), deal: 1, viewportTop: 300);

      // 300 ÷ 212 ≈ 1,42 cartão por cima: desce 300 e mostra a beirada.
      expect(first.shift.dy, closeTo(300 - 300 / 212 * 8, 1e-9));
      expect(first.scale, lessThan(1));
      expect(first.opacity, lessThan(1));
      expect(last.isFlat, isTrue);
    });

    test('a pilha vai embora junta quando o último chega ao alto', () {
      final first = WalletPose.of(_slot(0), deal: 1, viewportTop: 900);

      // Para de descer no lugar do último (424), com os dois de cima sobre
      // ele: 424 ÷ 212 = 2 beiradas de 8.
      expect(first.shift.dy, closeTo(424 - 2 * 8, 1e-9));
    });

    test('puxando além do topo, os cartões se afastam em leque', () {
      expect(WalletPose.of(_slot(2), deal: 1, pull: 40).shift.dy, 20);
      expect(WalletPose.of(_slot(0), deal: 1, pull: 40).shift.dy, 0);
    });
  });

  group('CajuiWalletStack', () {
    testWidgets('RNF-A11Y-08 o maço se abre uma vez e assenta em coluna', (
      tester,
    ) async {
      await _screenSize(tester);
      await tester.pumpWidget(_wallet());
      await tester.pump();

      // No primeiro quadro, o da frente está no lugar do primeiro.
      expect(_paintedTop(tester, 2), closeTo(_paintedTop(tester, 0) + 16, 2));

      await tester.pumpAndSettle();
      expect(_paintedTop(tester, 0), 100);
      expect(_paintedTop(tester, 1), 312);
      expect(_paintedTop(tester, 2), 524);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets(
      'RNF-A11Y-07 no reduzido é uma coluna desde o primeiro quadro',
      (tester) async {
        await _screenSize(tester);
        await tester.pumpWidget(
          _wallet(
            theme: CajuiThemeData.light(motionLevel: MotionLevel.reduced),
          ),
        );

        expect(tester.hasRunningAnimations, isFalse);
        expect(_paintedTop(tester, 2), 524);
      },
    );

    testWidgets('rolando, o cartão para no alto e o toque acha o de cima', (
      tester,
    ) async {
      await _screenSize(tester);
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final taps = <int>[];
      await tester.pumpWidget(_wallet(controller: controller, onTap: taps.add));
      await tester.pumpAndSettle();

      controller.jumpTo(250);
      await tester.pump();

      // Sem a pilha, o 1º estaria em -150; parado no alto, mostra a beirada.
      expect(_paintedTop(tester, 0), inInclusiveRange(-24, 0));
      expect(_paintedTop(tester, 1), 62);
      // Onde os dois se sobrepõem, quem está por cima recebe o toque.
      await tester.tapAt(const Offset(180, 120));
      expect(taps, [1]);
    });

    testWidgets('RNF-A11Y-04 em 360 com fonte a 200%, nada estoura', (
      tester,
    ) async {
      await _screenSize(tester);
      await tester.pumpWidget(_wallet(textScale: 2));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('dentro da entrada cinematográfica, abre no ritmo dela', (
      tester,
    ) async {
      await _screenSize(tester);
      await tester.pumpWidget(
        host(
          CajuiCinematicEntrance(
            child: SizedBox.fromSize(
              size: _screen,
              child: ListView(
                children: [
                  CajuiWalletStack(
                    children: [for (var i = 0; i < 3; i++) _card(i)],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(_paintedTop(tester, 2), lessThan(100));

      await tester.pump(CajuiDurations.slowest);
      await tester.pump(const Duration(milliseconds: 16));
      expect(_paintedTop(tester, 2), 424);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
