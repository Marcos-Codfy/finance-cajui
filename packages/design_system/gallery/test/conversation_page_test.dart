import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/src/shell/gallery_destination.dart';

import 'support/gallery_harness.dart';

void main() {
  testWidgets('a página Conversa mostra a fala comum e a que pede resposta', (
    tester,
  ) async {
    await openGallery(tester, page: GalleryDestination.conversation);

    expect(find.byType(CajuiChatBubble), findsWidgets);
    expect(find.byType(CajuiChatPrompt), findsNWidgets(5));
    expect(find.text('Desfazer tudo'), findsOneWidget);
    expect(find.textContaining('Posto Ipê, Uber e 99'), findsOneWidget);
  });

  testWidgets('escolhida a opção, a pergunta perde os chips e a resposta '
      'vira fala de quem usa', (tester) async {
    await openGallery(tester, page: GalleryDestination.conversation);
    final option = find.widgetWithText(CajuiChip, 'Conta minha');

    await tapVisible(tester, option);

    expect(option, findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CajuiChatBubble &&
            widget.fromUser &&
            widget.text == 'Conta minha',
      ),
      findsOneWidget,
    );

    await tapVisible(tester, find.text('Perguntar de novo'));
    expect(option, findsOneWidget);
  });
}
