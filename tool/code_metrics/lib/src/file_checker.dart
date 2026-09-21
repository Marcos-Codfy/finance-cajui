import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:code_metrics/src/function_collector.dart';
import 'package:code_metrics/src/limits.dart';
import 'package:code_metrics/src/nesting_visitor.dart';
import 'package:code_metrics/src/violation.dart';

/// Confere um arquivo Dart contra os limites do projeto.
///
/// Só faz análise sintática, sem resolver tipos: é o que deixa o verificador
/// rápido o bastante para rodar em todo commit.
class FileChecker {
  /// Cria o verificador com os [limits] dados.
  const new({this.limits = const Limits()});

  /// Os limites em vigor.
  final Limits limits;

  /// As violações de [content], o conteúdo do arquivo [path].
  ///
  /// Em arquivo de teste ([isTest]), `main` não tem limite de linhas: ela é o
  /// sumário dos casos, não lógica. Cada caso continua limitado pelo arquivo.
  List<Violation> check(String path, String content, {bool isTest = false}) {
    final parsed = parseString(content: content, throwIfDiagnostics: false);
    final lines = parsed.lineInfo;
    return [
      ..._fileLength(path, content),
      ..._publicTypes(path, parsed.unit, lines),
      for (final function in _functionsOf(parsed.unit))
        if (!(isTest && function.name == 'main'))
          ..._functionLength(path, function, lines),
      for (final function in _functionsOf(parsed.unit))
        ..._nesting(path, function, lines),
    ];
  }

  List<FoundFunction> _functionsOf(CompilationUnit unit) {
    final collector = FunctionCollector();
    unit.accept(collector);
    return collector.found;
  }

  List<Violation> _fileLength(String path, String content) {
    final count = '\n'.allMatches(content).length +
        (content.isEmpty || content.endsWith('\n') ? 0 : 1);
    if (count <= limits.maxFileLines) return const [];
    return [
      Violation(
        path: path,
        line: 1,
        rule: 'file-lines',
        message: '$count linhas; o limite é ${limits.maxFileLines}',
      ),
    ];
  }

  List<Violation> _functionLength(
    String path,
    FoundFunction function,
    LineInfo lines,
  ) {
    // Comentário de documentação e anotação não contam: a medida é do código.
    final first = function.node is AnnotatedNode
        ? (function.node as AnnotatedNode).firstTokenAfterCommentAndMetadata
        : function.node.beginToken;
    final start = lines.getLocation(first.offset).lineNumber;
    final end = lines.getLocation(function.node.end).lineNumber;
    final length = end - start + 1;
    if (length <= limits.maxFunctionLines) return const [];
    return [
      Violation(
        path: path,
        line: start,
        rule: 'function-lines',
        message:
            '${function.name} tem $length linhas; o limite é '
            '${limits.maxFunctionLines}',
      ),
    ];
  }

  List<Violation> _nesting(
    String path,
    FoundFunction function,
    LineInfo lines,
  ) {
    final visitor = NestingVisitor();
    function.body.accept(visitor);
    final deepest = visitor.deepestNode;
    if (visitor.deepest <= limits.maxNesting || deepest == null) {
      return const [];
    }
    return [
      Violation(
        path: path,
        line: lines.getLocation(deepest.offset).lineNumber,
        rule: 'nesting',
        message:
            '${function.name} chega a ${visitor.deepest} níveis de bloco; '
            'o limite é ${limits.maxNesting}',
      ),
    ];
  }

  List<Violation> _publicTypes(
    String path,
    CompilationUnit unit,
    LineInfo lines,
  ) {
    final sealed = _sealedNames(unit);
    final public = [
      for (final declaration in unit.declarations)
        if (_typeName(declaration) case final name? when !name.startsWith('_'))
          if (!_isSealedCase(declaration, sealed)) declaration,
    ];
    if (public.length <= limits.maxPublicTypes) return const [];
    final extra = public[limits.maxPublicTypes];
    return [
      Violation(
        path: path,
        line: lines.getLocation(extra.offset).lineNumber,
        rule: 'public-types',
        message:
            '${public.length} tipos públicos no arquivo; o limite é '
            '${limits.maxPublicTypes}',
      ),
    ];
  }

  /// Os tipos selados declarados no arquivo.
  Set<String> _sealedNames(CompilationUnit unit) => {
    for (final declaration in unit.declarations)
      if (declaration is ClassDeclaration && declaration.sealedKeyword != null)
        declaration.namePart.typeName.lexeme,
  };

  /// Um caso de hierarquia selada não conta como tipo à parte: o Dart obriga
  /// os casos a morar na biblioteca do tipo selado, e a família inteira é um
  /// conceito só — `Result` com `Ok` e `Err`, `Failure` com as suas falhas.
  bool _isSealedCase(CompilationUnitMember declaration, Set<String> sealed) {
    if (declaration is! ClassDeclaration) return false;
    final parents = [
      ?declaration.extendsClause?.superclass,
      ...?declaration.implementsClause?.interfaces,
    ];
    return parents.any((parent) => sealed.contains(parent.name.lexeme));
  }

  /// O nome do tipo declarado, ou nulo quando a declaração não é um tipo
  /// (função, variável, typedef, extensão).
  String? _typeName(CompilationUnitMember declaration) {
    return switch (declaration) {
      ClassDeclaration() => declaration.namePart.typeName.lexeme,
      EnumDeclaration() => declaration.namePart.typeName.lexeme,
      ExtensionTypeDeclaration() => declaration.namePart.typeName.lexeme,
      MixinDeclaration() => declaration.name.lexeme,
      _ => null,
    };
  }
}
