import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('os tons do cerrado no cartão', () {
    test('o texto claro passa de 4,5:1 nas duas pontas de cada tom', () {
      for (final skin in CajuiCardSkin.values) {
        if (skin == CajuiCardSkin.cajui) continue;
        for (final tone in [skin.top!, skin.bottom!]) {
          expect(
            WcagContrast.ratio(CajuiCardSkin.ink, tone),
            greaterThanOrEqualTo(4.5),
            reason: '${skin.label} reprova o texto do cartão',
          );
        }
      }
    });

    test('a palavra guardada volta ao mesmo tom; a desconhecida, ao de '
        'sempre', () {
      for (final skin in CajuiCardSkin.values) {
        expect(CajuiCardSkin.of(skin.slug), skin);
      }
      expect(CajuiCardSkin.of(null), CajuiCardSkin.cajui);
      expect(CajuiCardSkin.of('roxo-neon'), CajuiCardSkin.cajui);
    });

    test('as palavras não se repetem: cada uma é um tom só', () {
      final slugs = CajuiCardSkin.values.map((skin) => skin.slug);
      expect(slugs.toSet(), hasLength(CajuiCardSkin.values.length));
    });
  });
}
