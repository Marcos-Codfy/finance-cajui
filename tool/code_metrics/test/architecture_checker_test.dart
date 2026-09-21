import 'package:code_metrics/code_metrics.dart';
import 'package:test/test.dart';

List<String> _rules(String path, String content) => const ArchitectureChecker()
    .check(path, content)
    .map((violation) => violation.rule)
    .toList();

const _page = 'app/lib/src/features/ledger/presentation/entry_page.dart';
const _notifier = 'app/lib/src/features/ledger/application/entry_form.dart';
const _adapter = 'app/lib/src/features/ledger/infrastructure/file_store.dart';
const _money = 'packages/domain/lib/src/money/money.dart';
const _feature = 'package:cajui/src/features/ledger';

void main() {
  group('importação por camada', () {
    test('o domínio só importa Dart puro, meta e a si mesmo', () {
      const allowed = '''
import 'dart:math';
import 'package:domain/src/shared/result.dart';
import 'package:meta/meta.dart';
''';

      expect(_rules(_money, allowed), isEmpty);
      for (final uri in [
        'dart:io',
        'dart:html',
        'package:flutter/widgets.dart',
      ]) {
        expect(_rules(_money, "import '$uri';"), [
          'layer-imports',
        ], reason: uri);
      }
    });

    test('presentation não enxerga infrastructure', () {
      const import = "import '$_feature/infrastructure/file_store.dart';";

      expect(_rules(_page, import), ['layer-imports']);
      expect(_rules(_notifier, import), ['layer-imports']);
    });

    test('application não enxerga presentation, nem infrastructure a tela', () {
      const import = "import '$_feature/presentation/entry_page.dart';";

      expect(_rules(_notifier, import), ['layer-imports']);
      expect(_rules(_adapter, import), ['layer-imports']);
    });

    test('presentation e infrastructure enxergam application', () {
      const import = "import '$_feature/application/entry_form.dart';";

      expect(_rules(_page, import), isEmpty);
      expect(_rules(_adapter, import), isEmpty);
    });

    test('teste fica de fora: ele monta o que precisar', () {
      const import = "import '$_feature/infrastructure/file_store.dart';";

      expect(
        _rules('app/test/features/ledger/presentation/page_test.dart', import),
        isEmpty,
      );
    });
  });

  group('TODO sem dono', () {
    const orphan = '// TODO(dono): trocar pela chave do Keystore.\nvoid a() {}';
    const owned = '// TODO(dono): BL-029, trocar pela chave.\nvoid a() {}';

    test('TODO que não cita item do backlog é reprovado', () {
      expect(_rules(_adapter, orphan), ['orphan-todo']);
      expect(_rules(_adapter, owned), isEmpty);
    });

    test('vale também em teste e no fim do arquivo', () {
      const path = 'app/test/features/ledger/page_test.dart';

      expect(_rules(path, orphan), ['orphan-todo']);
      expect(_rules(path, 'void a() {}\n// TODO(dono): depois.'), [
        'orphan-todo',
      ]);
    });

    test('a palavra dentro de um texto não é promessa', () {
      expect(_rules(_adapter, "const a = 'TODO';"), isEmpty);
    });
  });

  group('fonte única do design', () {
    test('o app não cria cor nem estilo de texto', () {
      expect(_rules(_page, 'final a = Color(0xFF112233);'), ['raw-style']);
      expect(_rules(_page, 'const a = Color(0xFF112233);'), ['raw-style']);
      expect(_rules(_page, 'final a = Color.fromARGB(255, 1, 2, 3);'), [
        'raw-style',
      ]);
      expect(_rules(_page, 'const a = TextStyle(fontSize: 12);'), [
        'raw-style',
      ]);
    });

    test('pedir um papel ao tema passa', () {
      const themed = '''
Object color(dynamic theme) => theme.colors.action.primary;
Object style(dynamic theme) => theme.typography.body.copyWith(color: null);
''';

      expect(_rules(_page, themed), isEmpty);
    });

    test('o app não importa Material nem Cupertino, nem com show', () {
      const import =
          "import 'package:flutter/material.dart' show DefaultMaterialLocalizations;";

      expect(_rules(_page, import), ['layer-imports']);
      expect(_rules(_page, "import 'package:flutter/cupertino.dart';"), [
        'layer-imports',
      ]);
      expect(_rules(_page, "import 'package:flutter/widgets.dart';"), isEmpty);
    });

    test('duração de interface é token: Duration( só fora da tela', () {
      const duration = 'const wait = Duration(milliseconds: 300);';

      expect(_rules(_page, duration), ['raw-style']);
      expect(_rules(_adapter, duration), isEmpty);
    });

    test('o design system é onde a aparência pode nascer', () {
      expect(
        _rules(
          'packages/design_system/lib/src/tokens/primitives/cajui_palette.dart',
          'const a = Color(0xFF112233);',
        ),
        isEmpty,
      );
    });

    test('a violação de TODO aponta a linha do comentário', () {
      final violation = const ArchitectureChecker()
          .check(_page, 'void a() {}\n\n// TODO(dono): trocar depois.\n')
          .single;

      expect('$violation', startsWith('$_page:3  [orphan-todo]'));
    });

    test('a violação aponta a linha', () {
      final violation = const ArchitectureChecker()
          .check(_page, '\n\nfinal a = Color(0xFF112233);')
          .single;

      expect('$violation', startsWith('$_page:3  [raw-style] Color('));
    });
  });
}
