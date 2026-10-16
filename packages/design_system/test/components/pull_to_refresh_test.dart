import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

Widget _list(Future<void> Function() onRefresh, {ScrollPhysics? physics}) =>
    host(
      CajuiPullToRefresh(
        onRefresh: onRefresh,
        child: ListView(
          physics: physics,
          children: [
            for (var row = 0; row < 40; row++)
              SizedBox(height: 60, child: Text('linha $row')),
          ],
        ),
      ),
    );

void main() {
  group('puxar para atualizar', () {
    for (final (name, physics) in [
      ('trava no topo (Android)', const ClampingScrollPhysics()),
      ('estica (iOS)', const BouncingScrollPhysics()),
    ]) {
      testWidgets('do topo, puxar bem e soltar atualiza — $name', (
        tester,
      ) async {
        var calls = 0;
        await tester.pumpWidget(_list(() async => calls++, physics: physics));

        await tester.drag(find.text('linha 1'), const Offset(0, 300));
        await tester.pumpAndSettle();

        expect(calls, 1);
      });
    }

    testWidgets('um puxão curto não atualiza', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _list(() async => calls++, physics: const ClampingScrollPhysics()),
      );

      await tester.drag(find.text('linha 1'), const Offset(0, 30));
      await tester.pumpAndSettle();

      expect(calls, 0);
    });

    testWidgets('no meio da lista, puxar para baixo só rola', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _list(() async => calls++, physics: const ClampingScrollPhysics()),
      );
      await tester.drag(find.text('linha 1'), const Offset(0, -900));
      await tester.pumpAndSettle();

      await tester.drag(find.text('linha 20'), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(calls, 0);
    });
  });
}
