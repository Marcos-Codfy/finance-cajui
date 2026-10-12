import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/src/shell/gallery_destination.dart';

import 'support/gallery_harness.dart';

void main() {
  group('Início', () {
    testWidgets('mostra os números do mês no carrossel e a Planilha do mês', (
      tester,
    ) async {
      await openGallery(tester, page: GalleryDestination.home);

      expect(find.byType(CajuiCoverFlow), findsOneWidget);
      expect(find.text('Outubro'), findsOneWidget);
      expect(find.text('Sobra de outubro'), findsOneWidget);
      expect(
        find.text('Depois de pagar tudo · 69% da renda já está gasto'),
        findsOneWidget,
      );

      await scrollPhoneTo(tester, find.text('Planilha do mês'));
      expect(
        find.text('Leva outubro para o Excel ou o Planilhas Google'),
        findsOneWidget,
      );
      expect(find.text('Novo lançamento'), findsOneWidget);
    });

    testWidgets('o mês que não fecha diz quanto falta, sem julgamento', (
      tester,
    ) async {
      await openGallery(tester, page: GalleryDestination.home);
      await pickVariant(tester, 'Mês que não fecha');

      expect(find.text('Faltam para fechar outubro'), findsOneWidget);
      expect(
        find.text('107% da renda já está gasto. É a meta de corte do mês.'),
        findsOneWidget,
      );
      expect(find.textContaining('!'), findsNothing);
    });

    testWidgets('RN-1050 sem plano, o número é o que já saiu', (tester) async {
      await openGallery(tester, page: GalleryDestination.home);
      await pickVariant(tester, 'Primeiro uso');

      expect(find.text('Já saiu este mês'), findsOneWidget);
      expect(find.text('Sobra de outubro'), findsNothing);
    });

    testWidgets('a consulta pela web não lança nem fotografa', (tester) async {
      await openGallery(tester, page: GalleryDestination.home);
      await pickVariant(tester, 'Consulta pela web');

      expect(find.text('Novo lançamento'), findsNothing);
      expect(find.bySemanticsLabel('Fotografar comprovante'), findsNothing);
      expect(find.bySemanticsLabel('Ajustes'), findsOneWidget);
    });
  });

  group('Juju', () {
    testWidgets('abre com o mês de relance e as sugestões do app', (
      tester,
    ) async {
      await openGallery(tester, page: GalleryDestination.assistant);

      expect(
        find.text('SOBRAM ${BrlFormatter.format(131240)} NESTE MÊS'),
        findsOneWidget,
      );
      expect(find.text('Juju'), findsWidgets);

      await pickVariant(tester, 'Primeira conversa');
      expect(find.text('Oi, eu sou a Juju'), findsOneWidget);
      for (final suggestion in const [
        'Gastei 35 no mercado',
        'Quanto sobra neste mês?',
        'Para onde foi o dinheiro deste mês?',
      ]) {
        expect(find.widgetWithText(CajuiChip, suggestion), findsOneWidget);
      }
    });

    testWidgets('RN-1113 a RN-1119 o extrato é conferido, lançado e desfeito', (
      tester,
    ) async {
      await openGallery(tester, page: GalleryDestination.assistant);
      await pickVariant(tester, 'Extrato pela Juju');
      expect(
        find.textContaining('Mercado — 12 compras', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Pode lançar (57)'), findsOneWidget);

      await tapVisible(tester, anywhere('Ver as linhas'));
      expect(anywhere('02/10 · Assaí'), findsOneWidget);
      expect(anywhere('Ver as linhas'), findsNothing);

      await tapVisible(tester, anywhere('Confere'));
      await tapVisible(tester, chipAnywhere('Alguém da casa'));
      await tapVisible(tester, chipAnywhere('Padaria'));
      expect(find.text('Pode lançar (58)'), findsOneWidget);

      await tester.tap(find.text('Pode lançar (58)'));
      await settle(tester);
      expect(
        find.textContaining('Lancei 58 lançamentos.', skipOffstage: false),
        findsOneWidget,
      );

      await tapVisible(tester, anywhere('Desfazer'));
      expect(anywhere('Desfiz os 58 lançamentos.'), findsOneWidget);
      expect(anywhere('Desfazer'), findsNothing);
    });

    testWidgets('RN-1115 conferir depois não lança nada', (tester) async {
      await openGallery(tester, page: GalleryDestination.assistant);
      await pickVariant(tester, 'Extrato pela Juju');

      await tester.tap(find.text('Conferir depois'));
      // A conversa desce até a fala nova depois do quadro: espera assentar.
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Nada foi lançado', skipOffstage: false),
        findsOneWidget,
      );
      expect(anywhere('Confere'), findsNothing);
      expect(anywhere('Pode lançar (57)'), findsNothing);
      expect(anywhere('Conferir depois'), findsNothing);
    });

    testWidgets('o extrato lançado abre no fim, com o Desfazer à vista', (
      tester,
    ) async {
      await openGallery(tester, page: GalleryDestination.assistant);
      await pickVariant(tester, 'Extrato lançado');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Lancei 58 lançamentos.', skipOffstage: false),
        findsOneWidget,
      );
      // Abriu no fim: o Desfazer está à vista, sem rolar.
      expect(find.text('Desfazer'), findsOneWidget);
    });
  });
}
