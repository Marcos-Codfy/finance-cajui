import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/src/shell/gallery_destination.dart';

import 'support/gallery_harness.dart';

void main() {
  testWidgets('a troca de página da gallery é uma passagem: quadro a quadro, '
      'as duas páginas nunca aparecem juntas', (tester) async {
    await openGallery(tester);

    await tester.tap(find.text(GalleryDestination.contrast.title).first);
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      final shown = tester
          .widgetList<FadeTransition>(find.byType(FadeTransition))
          .where((fade) => fade.child is KeyedSubtree)
          .where((fade) => fade.opacity.value > 0.05);
      expect(shown.length, lessThanOrEqualTo(1), reason: 'quadro $frame');
    }
    await settle(tester);
    expect(find.text('Contraste'), findsWidgets);
  });
}
