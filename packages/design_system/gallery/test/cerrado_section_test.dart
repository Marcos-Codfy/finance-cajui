import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/src/pages/components/cerrado_section.dart';
import 'package:gallery/src/shell/gallery_destination.dart';

import 'support/gallery_harness.dart';

void main() {
  testWidgets('a página de estados mostra as três ilustrações do Cerrado, '
      'cada uma no vazio em que o app a usa', (tester) async {
    await openGallery(tester, page: GalleryDestination.states);
    final section = find.byType(CerradoSection, skipOffstage: false);
    await tester.ensureVisible(section);
    await settle(tester);

    final kinds = tester
        .widgetList<CajuiCerradoArt>(
          find.descendant(
            of: section,
            matching: find.byType(CajuiCerradoArt, skipOffstage: false),
          ),
        )
        .map((art) => art.kind);

    expect(kinds, CajuiCerrado.values);
    expect(anywhere('Nenhum cartão ainda'), findsOneWidget);
  });

  testWidgets('com movimento reduzido, as ilustrações da página ficam '
      'paradas', (tester) async {
    await openGallery(tester, page: GalleryDestination.states);
    await useSetting(tester, 'Reduzido');
    await tester.ensureVisible(
      find.byType(CerradoSection, skipOffstage: false),
    );
    await settle(tester);

    expect(tester.hasRunningAnimations, isFalse);
  });
}
