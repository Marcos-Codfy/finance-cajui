import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

void main() {
  group('as bolinhas da cor do cartão', () {
    testWidgets('uma bolinha por tom, e o toque avisa o tom tocado', (
      tester,
    ) async {
      CajuiCardSkin? picked;
      await tester.pumpWidget(
        host(
          CajuiCardSkinPicker(
            selected: CajuiCardSkin.cajui,
            onChanged: (skin) => picked = skin,
          ),
        ),
      );

      for (final skin in CajuiCardSkin.values) {
        expect(find.bySemanticsLabel(skin.label), findsOneWidget);
      }
      await tester.tap(find.bySemanticsLabel('Ipê-roxo'));

      expect(picked, CajuiCardSkin.ipeRoxo);
    });

    testWidgets('a escolhida leva o visto, e só ela', (tester) async {
      await tester.pumpWidget(
        host(
          CajuiCardSkinPicker(
            selected: CajuiCardSkin.buriti,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.byType(CajuiIcon), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Buriti')),
        isSemantics(isSelected: true, hasSelectedState: true),
      );
    });
  });
}
