import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/src/pages/screens/widget/glass_widget.dart';
import 'package:gallery/src/pages/screens/widget/glass_widget_small.dart';
import 'package:gallery/src/pages/screens/widget/widget_demo.dart';
import 'package:gallery/src/shell/gallery_destination.dart';

import 'support/gallery_harness.dart';

void main() {
  testWidgets('o número do widget abre o Cajui crescendo de dentro dele, e '
      'os números do Início chegam pelo vidro', (tester) async {
    await openGallery(tester, page: GalleryDestination.homeWidget);
    expect(find.byType(CajuiAurora), findsNWidgets(3));
    expect(find.byType(CajuiGlassArrival), findsNothing);

    await tapVisible(
      tester,
      find.descendant(
        of: find.byType(GlassWidget),
        matching: anywhere('SOBRA DE OUTUBRO'),
      ),
    );

    final arrival = tester.widget<CajuiGlassArrival>(
      find.byType(CajuiGlassArrival),
    );
    expect(arrival.arrival, 1);

    await tapVisible(tester, anywhere('Voltar à tela inicial'));
    expect(find.byType(CajuiGlassArrival), findsNothing);
  });

  testWidgets('o widget do mês que virou não mostra número: pede para abrir '
      'o app', (tester) async {
    await openGallery(tester, page: GalleryDestination.homeWidget);
    await pickVariant(tester, 'Mês novo');

    // Os três widgets.
    expect(anywhere('MÊS NOVO'), findsNWidgets(3));
    expect(anywhere('Abra o Cajui para ver o mês.'), findsOneWidget);
    expect(anywhere('Aluguel'), findsNothing);
    expect(anywhere('Nenhuma conta a vencer por agora.'), findsNothing);
  });

  testWidgets('o grande mostra as contas a vencer, nome e dia; o pequeno, só '
      'o número, e o toque nele também abre o Cajui', (tester) async {
    await openGallery(tester, page: GalleryDestination.homeWidget);
    final small = find.byType(GlassWidgetSmall);

    for (final (name, day) in WidgetDemo.sampleBills) {
      expect(anywhere(name), findsOneWidget);
      expect(anywhere(day), findsOneWidget);
    }
    expect(
      find.descendant(of: small, matching: anywhere('Aluguel')),
      findsNothing,
    );

    await tapVisible(
      tester,
      find.descendant(of: small, matching: anywhere('SOBRA DE OUTUBRO')),
    );
    expect(
      tester.widget<CajuiGlassArrival>(find.byType(CajuiGlassArrival)).arrival,
      1,
    );
  });

  testWidgets('sem contas a vencer, o grande diz isso em vez de uma lista '
      'vazia', (tester) async {
    await openGallery(tester, page: GalleryDestination.homeWidget);
    await pickVariant(tester, 'Sem contas a vencer');

    expect(anywhere('Nenhuma conta a vencer por agora.'), findsOneWidget);
    expect(anywhere('Aluguel'), findsNothing);
  });

  testWidgets('o widget tem os três atalhos, cada um com nome para o leitor '
      'de tela, e o "+" é o novo gasto', (tester) async {
    await openGallery(tester, page: GalleryDestination.homeWidget);

    // Dentro do widget: o menu da gallery também tem uma página "Novo gasto".
    Finder inWidget(String label) => find.descendant(
      of: find.byType(GlassWidget),
      matching: find.bySemanticsLabel(label),
    );
    expect(inWidget('Fotografar comprovante'), findsOneWidget);
    expect(inWidget('Escolher da galeria'), findsOneWidget);
    expect(inWidget('Novo gasto'), findsOneWidget);
  });

  testWidgets('o olho do grande esconde os valores dos três widgets, e o '
      'grande diz de quando é o número', (tester) async {
    await openGallery(tester, page: GalleryDestination.homeWidget);
    expect(anywhere('SALDO DO VALE'), findsOneWidget);
    expect(
      find.textContaining('Atualizado às', skipOffstage: false),
      findsOneWidget,
    );

    await tapVisible(tester, find.bySemanticsLabel('Esconder os valores'));

    expect(anywhere(WidgetDemo.hiddenAmount), findsNWidgets(3));
    expect(find.bySemanticsLabel('Mostrar os valores'), findsOneWidget);
  });
}
