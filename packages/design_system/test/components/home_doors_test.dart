import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

CajuiTile _tile(String title, VoidCallback onPressed) => CajuiTile(
  icon: CajuiIconData.card,
  title: title,
  subtitle: 'O que tem em $title',
  onPressed: onPressed,
);

void main() {
  group('as portas do Início', () {
    testWidgets('a porta diz nome e frase ao leitor de tela, e abre', (
      tester,
    ) async {
      var opened = 0;
      await tester.pumpWidget(host(_tile('Cartões', () => opened++)));

      await tester.tap(find.bySemanticsLabel('Cartões'));

      expect(opened, 1);
    });

    testWidgets('a grade põe duas por linha, e a sobra fica sozinha', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          CajuiTileGrid(
            children: [
              for (final name in ['A', 'B', 'C']) _tile(name, () {}),
            ],
          ),
        ),
      );

      final a = tester.getTopLeft(find.text('A'));
      final b = tester.getTopLeft(find.text('B'));
      final c = tester.getTopLeft(find.text('C'));
      expect(b.dy, a.dy);
      expect(b.dx, greaterThan(a.dx));
      expect(c.dy, greaterThan(a.dy));
    });

    testWidgets('o "Mais" guarda as portas fechado e mostra aberto', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const CajuiDisclosure(title: 'Mais', children: [Text('Vale')])),
      );
      expect(find.text('Vale'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Mais'));
      await tester.pumpAndSettle();
      expect(find.text('Vale'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Mais'));
      await tester.pumpAndSettle();
      expect(find.text('Vale'), findsNothing);
    });
  });
}
