import 'package:cajui/src/core/appearance/block_look.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('a cor e o ícone de cada grupo', () {
    for (final (name, theme) in [
      ('claro', CajuiThemeData.light()),
      ('escuro', CajuiThemeData.dark()),
    ]) {
      test('no tema $name, cada grupo tem cor própria', () {
        final colors = {
          for (final block in Block.values)
            BlockLook.colorOf(block, theme.colors),
        };

        expect(colors, hasLength(Block.values.length));
      });
    }

    test('cada grupo tem ícone próprio, e assinatura é a que repete', () {
      final icons = {for (final block in Block.values) BlockLook.iconOf(block)};

      expect(icons, hasLength(Block.values.length));
      expect(BlockLook.iconOf(Block.subscription), CajuiIconData.repeat);
    });
  });
}
