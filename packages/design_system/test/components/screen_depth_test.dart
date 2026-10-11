import 'package:design_system/design_system.dart';
import 'package:design_system/src/components/depth/depth_item.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

const _screen = Size(360, 640);

Widget _home({bool depth = false, bool cinematic = false, Object? month}) {
  return host(
    SizedBox.fromSize(
      size: _screen,
      child: CajuiScreen(
        title: 'Início',
        overline: 'Outubro',
        depth: depth,
        cinematic: cinematic,
        replayKey: month,
        children: [
          for (var i = 0; i < 6; i++)
            SizedBox(height: 180, child: Text('Seção $i')),
        ],
      ),
    ),
  );
}

Future<void> _screenSize(WidgetTester tester) async {
  tester.view.physicalSize = _screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('sem pedir, a tela continua a lista de sempre', (tester) async {
    await _screenSize(tester);
    await tester.pumpWidget(_home());

    expect(find.byType(DepthItem), findsNothing);
    expect(find.byType(CajuiCinematicShot), findsNothing);
  });

  testWidgets('com profundidade, só a seção cortada pela borda curva', (
    tester,
  ) async {
    await _screenSize(tester);
    await tester.pumpWidget(_home(depth: true));

    double lens(String label) => tester
        .renderObject<RenderBox>(find.text(label))
        .getTransformTo(null)
        .entry(3, 2);
    expect(lens('Início'), 0);
    expect(lens('Seção 0'), 0);
    // O alto ocupa uns 110; a 3ª seção sai cortada pela borda de baixo.
    expect(lens('Seção 2'), isNot(0));
  });

  testWidgets('RNF-A11Y-08 com entrada, o título e cada filho chegam uma vez', (
    tester,
  ) async {
    await _screenSize(tester);
    await tester.pumpWidget(_home(depth: true, cinematic: true, month: 10));

    // O alto é a tomada 0; os filhos vêm depois, na ordem.
    expect(
      tester
          .widget<CajuiCinematicShot>(
            find.ancestor(
              of: find.text('Início'),
              matching: find.byType(CajuiCinematicShot),
            ),
          )
          .index,
      0,
    );
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(_home(depth: true, cinematic: true, month: 11));
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
  });
}
