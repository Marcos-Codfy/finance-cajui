import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/src/shell/gallery_destination.dart';

import 'support/gallery_harness.dart';

void main() {
  testWidgets('o número do widget abre o Cajui crescendo de dentro dele, e '
      'os números do Início chegam pelo vidro', (tester) async {
    await openGallery(tester, page: GalleryDestination.homeWidget);
    expect(find.byType(CajuiAurora), findsOneWidget);
    expect(find.byType(CajuiGlassArrival), findsNothing);

    await tapVisible(tester, anywhere('SOBRA DE OUTUBRO'));

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

    expect(anywhere('MÊS NOVO'), findsOneWidget);
    expect(anywhere('Abra o Cajui para ver o mês.'), findsOneWidget);
  });
}
