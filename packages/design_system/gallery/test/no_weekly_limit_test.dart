import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/src/shell/gallery_destination.dart';
import 'package:gallery/src/shell/gallery_group.dart';

import 'support/gallery_harness.dart';

/// A raiz "semana" como começo de palavra — "semana", "semanal",
/// "semanas" —, em qualquer caixa. O limite semanal saiu do app em
/// 11/10/2026 a pedido do dono (BL-103), e a gallery é a vitrine do app:
/// mostrar uma tela que não existe mais é mentir para quem a olha. Procurar
/// a raiz, e não frases, prende também o "Limite semanal" que uma lista de
/// frases deixaria passar.
final _weekly = RegExp('(^|[^a-zà-ú])semana', caseSensitive: false);

String? _weeklyIn(String text) => _weekly.firstMatch(text)?.group(0);

void _expectNoWeek(WidgetTester tester, String where) {
  for (final text in treeTexts(tester)) {
    expect(_weeklyIn(text), isNull, reason: '$where: "$text"');
  }
}

void main() {
  testWidgets('BL-103 nenhuma página nem estado de tela fala do limite '
      'semanal', (tester) async {
    await openGallery(tester);

    for (final destination in GalleryDestination.values) {
      await goTo(tester, destination);
      _expectNoWeek(tester, destination.title);
      if (destination.group != GalleryGroup.screens) continue;
      for (final label in variantLabels(tester)) {
        await pickVariant(tester, label);
        _expectNoWeek(tester, '${destination.title} · $label');
      }
    }
  });

  test('BL-103 nenhum texto do código da gallery fala do limite semanal', () {
    // A árvore só monta o que está perto da tela; o código tem tudo.
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in sources) {
      for (final (index, line) in file.readAsLinesSync().indexed) {
        if (line.trimLeft().startsWith('//')) continue;
        expect(_weeklyIn(line), isNull, reason: '${file.path}:${index + 1}');
      }
    }
  });
}
