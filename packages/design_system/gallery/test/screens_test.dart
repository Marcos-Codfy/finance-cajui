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
        find.textContaining('Assaí, Atacadão, Carrefour', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Pode lançar (57)'), findsOneWidget);

      await tapVisible(tester, anywhere('Ver as linhas'));
      expect(anywhere('02/10 · Assaí'), findsOneWidget);
      expect(anywhere('Esconder as linhas'), findsOneWidget);

      await tapVisible(tester, anywhere('Confere'));
      await tapVisible(tester, chipAnywhere('Alguém da casa'));
      await tapVisible(tester, chipAnywhere('Padaria'));
      expect(find.text('Pode lançar (58)'), findsOneWidget);
      // O "Confere" do que já estava; o primeiro virou fala de quem usa.
      await tapVisible(tester, anywhere('Confere').last);
      expect(
        anywhere('Tudo conferido: 58 lançamentos prontos para entrar.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Pode lançar (58)'));
      await settle(tester);
      expect(
        find.textContaining('Lancei 58 lançamentos.', skipOffstage: false),
        findsOneWidget,
      );

      await tapVisible(tester, anywhere('Desfazer tudo'));
      expect(anywhere('Desfiz os 58 lançamentos.'), findsOneWidget);
      expect(anywhere('Desfazer tudo'), findsNothing);
      expect(find.text('Pode lançar (58)'), findsOneWidget);
    });

    testWidgets('RN-1114 o Pix que vira gasto ganha a pergunta da categoria '
        'dele', (tester) async {
      await openGallery(tester, page: GalleryDestination.assistant);
      await pickVariant(tester, 'Extrato pela Juju');

      await tapVisible(tester, anywhere('Confere'));
      await tapVisible(tester, chipAnywhere('É um gasto'));
      expect(find.text('Pode lançar (57)'), findsOneWidget);
      await tapVisible(tester, chipAnywhere('Transporte'));
      await tapVisible(tester, chipAnywhere('Padaria'));

      expect(find.text('Pode lançar (59)'), findsOneWidget);
    });

    testWidgets('RN-1115 conferir depois não lança nada e fecha a conversa', (
      tester,
    ) async {
      await openGallery(tester, page: GalleryDestination.assistant);
      await pickVariant(tester, 'Extrato pela Juju');
      await tapVisible(tester, anywhere('Confere'));
      await tapVisible(tester, chipAnywhere('Alguém da casa'));

      await tester.tap(find.text('Conferir depois'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Lancei', skipOffstage: false), findsNothing);
      expect(chipAnywhere('Alguém da casa'), findsNothing);
      expect(find.text('Pode lançar (57)'), findsOneWidget);
    });

    testWidgets('o extrato lançado abre no fim, com o Desfazer tudo à vista', (
      tester,
    ) async {
      await openGallery(tester, page: GalleryDestination.assistant);
      await pickVariant(tester, 'Extrato lançado');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Lancei 58 lançamentos.', skipOffstage: false),
        findsOneWidget,
      );
      // Abriu no fim: o "Desfazer tudo" está à vista, sem rolar.
      expect(find.text('Desfazer tudo'), findsOneWidget);
      expect(find.text('Pronto'), findsOneWidget);
    });
  });
}
