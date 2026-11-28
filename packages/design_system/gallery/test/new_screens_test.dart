import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/src/shell/gallery_destination.dart';

import 'support/gallery_harness.dart';

/// O chip [label] marcado ou não, à vista ou não.
bool _selected(WidgetTester tester, String label) =>
    tester.widget<CajuiChip>(chipAnywhere(label)).selected;

void main() {
  group('Lançamentos', () {
    testWidgets('a lista do mês mostra o já gasto por moeda, a lupa e os '
        'atalhos, e o rodapé numa linha', (tester) async {
      await openGallery(tester, page: GalleryDestination.entries);

      expect(anywhere('Já gasto em dinheiro'), findsOneWidget);
      expect(anywhere('Já gasto no vale alimentação'), findsOneWidget);
      expect(find.bySemanticsLabel('Buscar nos lançamentos'), findsOneWidget);
      for (final shortcut in ['Só vale alimentação', 'Só cartão']) {
        expect(_selected(tester, shortcut), isFalse, reason: shortcut);
      }
      expect(anywhere('Padaria Pão Quente'), findsOneWidget);
      expect(anywhere('Gastei'), findsOneWidget);
    });

    testWidgets('o atalho ligado fica marcado e deixa só a compra do vale; '
        'o filtro sem resultado diz o que tirar', (tester) async {
      await openGallery(tester, page: GalleryDestination.entries);

      await pickVariant(tester, 'Atalho ligado');
      expect(_selected(tester, 'Só vale alimentação'), isTrue);
      expect(anywhere('Mercado Boa Compra'), findsOneWidget);
      expect(anywhere('Padaria Pão Quente'), findsNothing);

      await pickVariant(tester, 'Filtro sem resultado');
      expect(anywhere('Tire “Só cartão” para ver mais.'), findsOneWidget);
      expect(anywhere('Tirar os filtros'), findsOneWidget);
    });

    testWidgets('a busca aberta tem o fechar e vira chip', (tester) async {
      await openGallery(tester, page: GalleryDestination.entries);

      await pickVariant(tester, 'Busca aberta');

      expect(find.bySemanticsLabel('Fechar a busca'), findsOneWidget);
      expect(_selected(tester, '“padaria”'), isTrue);
    });
  });

  group('Novo gasto', () {
    testWidgets('em branco, os gastos de sempre vêm no alto e o botão diz '
        'que falta o valor', (tester) async {
      await openGallery(tester, page: GalleryDestination.newSpend);

      expect(anywhere('Gastos de sempre'), findsOneWidget);
      expect(
        anywhere('Padaria Pão Quente · ${BrlFormatter.format(1250)}'),
        findsOneWidget,
      );
      final button = tester.widget<CajuiButton>(
        find.ancestor(
          of: anywhere('Falta o valor'),
          matching: find.byType(CajuiButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('o valor fora do comum pergunta, com o normal da categoria, '
        'no lugar do botão', (tester) async {
      await openGallery(tester, page: GalleryDestination.newSpend);

      await pickVariant(tester, 'Valor fora do comum');

      expect(
        anywhere('Confere o valor: ${BrlFormatter.format(150000)}?'),
        findsOneWidget,
      );
      expect(anywhere('Está certo, salvar'), findsOneWidget);
      expect(anywhere('Corrigir o valor'), findsOneWidget);
      expect(anywhere('Lançar'), findsNothing);
    });

    testWidgets('sem nada repetido, oferece repetir o último', (tester) async {
      await openGallery(tester, page: GalleryDestination.newSpend);

      await pickVariant(tester, 'Primeiro gasto');

      expect(anywhere('Repetir o último'), findsOneWidget);
      expect(anywhere('Gastos de sempre'), findsNothing);
    });
  });

  group('Ajustes e ajuda', () {
    testWidgets('no celular, a ajuda vem primeiro e a chave de API aparece; '
        'na web, o "Sair" toma o lugar dela', (tester) async {
      await openGallery(tester, page: GalleryDestination.settings);

      // A linha dos Ajustes, e o nome do estado no seletor.
      expect(anywhere('Como o Cajui conta'), findsNWidgets(2));
      expect(anywhere('Chave de API'), findsOneWidget);

      await pickVariant(tester, 'Na consulta pela web');
      expect(anywhere('Chave de API'), findsNothing);
      expect(anywhere('Sair'), findsOneWidget);
    });

    testWidgets('a ajuda abre com o vale lido, e o vale nunca se soma ao '
        'dinheiro', (tester) async {
      await openGallery(tester, page: GalleryDestination.settings);

      await pickVariant(tester, 'Como o Cajui conta');

      expect(
        find.textContaining('nunca se soma ao dinheiro', skipOffstage: false),
        findsOneWidget,
      );
      expect(anywhere('Renda do mês'), findsOneWidget);
    });
  });
}
