import 'package:code_metrics/code_metrics.dart';
import 'package:test/test.dart';

/// Uma função com [bodyLines] linhas de corpo: assinatura e chave somam 2.
String _function(int bodyLines, {String name = 'work'}) => [
  'void $name() {',
  for (var i = 0; i < bodyLines; i++) '  print($i);',
  '}',
  '',
].join('\n');

List<String> _rules(String content, {bool isTest = false}) =>
    const FileChecker()
        .check('sample.dart', content, isTest: isTest)
        .map((violation) => violation.rule)
        .toList();

void main() {
  group('linhas por função', () {
    test('30 linhas passam, 31 não', () {
      expect(_rules(_function(28)), isEmpty);
      expect(_rules(_function(29)), ['function-lines']);
    });

    test('comentário de documentação não entra na conta', () {
      final documented = '/// Explica.\n' * 10 + _function(28);

      expect(_rules(documented), isEmpty);
    });

    test('em arquivo de teste, main não tem limite; o resto tem', () {
      expect(_rules(_function(40, name: 'main'), isTest: true), isEmpty);
      expect(_rules(_function(40), isTest: true), ['function-lines']);
    });

    test('a violação diz o arquivo, a linha e a medida', () {
      final violation = const FileChecker()
          .check('lib/a.dart', '\n\n${_function(40)}')
          .single;

      expect(
        violation.toString(),
        startsWith('lib/a.dart:3  [function-lines]'),
      );
      expect(violation.message, contains('42 linhas'));
    });
  });

  group('linhas por arquivo', () {
    test('300 linhas passam, 301 não', () {
      expect(_rules('// linha\n' * 300), isEmpty);
      expect(_rules('// linha\n' * 301), ['file-lines']);
    });
  });

  group('aninhamento', () {
    const threeDeep = '''
void f(List<int> xs) {
  for (final x in xs) {
    if (x > 0) {
      while (x > 1) {}
    }
  }
}
''';
    const fourDeep = '''
void f(List<int> xs) {
  for (final x in xs) {
    if (x > 0) {
      while (x > 1) {
        if (x > 2) {}
      }
    }
  }
}
''';
    const elseIfChain = '''
void f(int x) {
  if (x == 1) {
  } else if (x == 2) {
  } else if (x == 3) {
  } else if (x == 4) {
  } else {}
}
''';

    test('três níveis passam, quatro não', () {
      expect(_rules(threeDeep), isEmpty);
      expect(_rules(fourDeep), ['nesting']);
    });

    test('cadeia de else if fica no mesmo nível', () {
      expect(_rules(elseIfChain), isEmpty);
    });
  });

  group('tipos públicos por arquivo', () {
    test('um tipo público e quantos privados quiser', () {
      expect(_rules('class A {}\nclass _B {}\nenum _C { x }\n'), isEmpty);
    });

    test('dois tipos públicos, mesmo de espécies diferentes, não passam', () {
      expect(_rules('class A {}\nenum B { x }\n'), ['public-types']);
    });

    test('os casos de uma hierarquia selada contam como um tipo só', () {
      const family = '''
sealed class Result {}
final class Ok extends Result {}
final class Err implements Result {}
''';

      expect(_rules(family), isEmpty);
      expect(_rules('$family\nclass Other {}\n'), ['public-types']);
    });

    test('typedef e extensão não contam como tipo', () {
      const content =
          'class A {}\ntypedef F = void Function();\n'
          'extension on A {}\n';

      expect(_rules(content), isEmpty);
    });
  });
}
