import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/src/shell/gallery_destination.dart';

import 'support/gallery_harness.dart';

void main() {
  testWidgets('página curta começa no alto da janela, sem boiar no meio', (
    tester,
  ) async {
    await openGallery(
      tester,
      size: const Size(1280, 2400),
      page: GalleryDestination.icons,
    );

    final title = tester.getTopLeft(find.text('Ícones').last);
    expect(title.dy, lessThan(200));
  });

  testWidgets('os exemplares de uma fileira têm o nome do estado na mesma '
      'altura', (tester) async {
    await openGallery(tester, page: GalleryDestination.states);

    final info = tester.getTopLeft(
      find.textContaining('Informação', findRichText: true),
    );
    final positive = tester.getTopLeft(
      find.textContaining('Confirmação', findRichText: true),
    );
    expect(positive.dy, info.dy);
  });

  testWidgets('o nome do estado vem em português, com o nome da API ao '
      'lado', (tester) async {
    await openGallery(tester, page: GalleryDestination.action);

    expect(
      find.textContaining('Principal  primary', findRichText: true),
      findsWidgets,
    );
    expect(find.text('primary'), findsNothing);
  });

  testWidgets('a página diz onde está e o rodapé leva à próxima', (
    tester,
  ) async {
    await openGallery(tester, page: GalleryDestination.action);
    final siblings = GalleryDestination.inGroup(GalleryDestination.action.group)
        .toList();
    final where =
        '${GalleryDestination.action.group.title} · '
                '${siblings.indexOf(GalleryDestination.action) + 1} de '
                '${siblings.length}'
            .toUpperCase();
    expect(find.text(where), findsOneWidget);

    final next = GalleryDestination.values[GalleryDestination.action.index + 1];
    await tapVisible(
      tester,
      find.bySemanticsLabel('Próxima página: ${next.title}'),
    );

    // Na página nova, o rodapé aponta de volta para a de antes.
    expect(
      find.bySemanticsLabel(
        'Página anterior: ${GalleryDestination.action.title}',
      ),
      findsOneWidget,
    );
  });
}
