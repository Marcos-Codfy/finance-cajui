import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gallery/src/shell/gallery_destination.dart';
import 'package:gallery/src/shell/gallery_group.dart';

import 'support/gallery_harness.dart';

/// As frases do limite semanal, que saiu do app em 11/10/2026 a pedido do
/// dono (BL-103). A gallery é a vitrine do app: mostrar uma tela que não
/// existe mais é mentir para quem a olha.
const _weekly = [
  'por semana',
  'esta semana',
  'nesta semana',
  'limite da semana',
  'semana partida',
];

String? _weeklyIn(String text) {
  final lower = text.toLowerCase();
  for (final phrase in _weekly) {
    if (lower.contains(phrase)) return phrase;
  }
  return null;
}

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
