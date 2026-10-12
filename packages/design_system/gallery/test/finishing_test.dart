import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/src/pages/screens/shared/phone_frame.dart';
import 'package:gallery/src/shell/gallery_author.dart';
import 'package:gallery/src/shell/gallery_destination.dart';

import 'support/gallery_harness.dart';

void main() {
  testWidgets('Faça e evite: cada regra com o certo e o que o app nunca faz', (
    tester,
  ) async {
    await openGallery(tester, page: GalleryDestination.doDont);

    expect(anywhere('Faça'), findsNWidgets(4));
    expect(anywhere('Evite'), findsNWidgets(4));
  });

  testWidgets('na Cor da falta, os dois aparelhos começam na mesma altura', (
    tester,
  ) async {
    await openGallery(tester, page: GalleryDestination.shortfall);

    final phones = find.byType(PhoneFrame);
    expect(phones, findsNWidgets(2));
    expect(
      tester.getTopLeft(phones.at(0)).dy,
      tester.getTopLeft(phones.at(1)).dy,
    );
    expect(anywhere('Barro · a escolhida'), findsOneWidget);
  });

  testWidgets('o estado que só se vê em movimento tem selo na vitrine', (
    tester,
  ) async {
    await openGallery(tester, page: GalleryDestination.screenStates);

    expect(anywhere('Com animação'), findsOneWidget);
  });

  testWidgets('a visão geral diz quem fez e leva ao perfil', (tester) async {
    await openGallery(tester);

    expect(find.byType(GalleryAuthor), findsOneWidget);
    expect(anywhere('Perfil no GitHub'), findsOneWidget);
  });
}
