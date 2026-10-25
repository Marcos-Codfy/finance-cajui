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

    testWidgets(
      'as quatro portas têm o mesmo tamanho, de frase curta ou longa',
      (tester) async {
        // Foi o defeito do teste de 22/10: o botão em volta do cartão o
        // encolhia ao tamanho do texto, e "Tudo quitado" ficava menor que
        // "Quanto do limite já foi usado no mês".
        const subtitles = [
          '17 este mês',
          'Entra um valor longo · sai do bolso outro valor longo',
          'Quanto do limite já foi usado no mês',
          'Tudo quitado',
        ];
        await tester.pumpWidget(
          host(
            CajuiTileGrid(
              children: [
                for (final (index, subtitle) in subtitles.indexed)
                  CajuiTile(
                    icon: CajuiIconData.card,
                    title: 'Porta $index',
                    subtitle: subtitle,
                    onPressed: () {},
                  ),
              ],
            ),
          ),
        );

        final cards = [
          for (var i = 0; i < subtitles.length; i++)
            tester.getRect(
              find
                  .descendant(
                    of: find.byType(CajuiTile).at(i),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            ),
        ];

        expect({for (final card in cards) card.width}, hasLength(1));
        expect({for (final card in cards) card.height}, hasLength(1));
        expect(cards[0].left, cards[2].left);
        expect(cards[1].left, cards[3].left);
      },
    );

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
