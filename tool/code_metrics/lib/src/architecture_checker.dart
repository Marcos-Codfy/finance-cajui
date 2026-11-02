import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:code_metrics/src/layer_rules.dart';
import 'package:code_metrics/src/raw_style_visitor.dart';
import 'package:code_metrics/src/todo_finder.dart';
import 'package:code_metrics/src/violation.dart';

/// Confere as fronteiras que nenhum lint pronto cobra (ADR-014): quem pode
/// importar quem, e onde a aparência pode ser definida.
///
/// O caminho do arquivo decide que regras valem. Por isso ele chega sempre
/// relativo à raiz do repositório e com barra normal.
class ArchitectureChecker {
  /// Cria o verificador.
  const new();

  /// As violações de [content], o conteúdo do arquivo [path].
  List<Violation> check(String path, String content) {
    final parsed = parseString(content: content, throwIfDiagnostics: false);
    return [
      // Camada e aparência são regra do código de produção: teste monta o
      // que precisar. `TODO` sem dono não tem desculpa em lugar nenhum.
      if (path.contains('/lib/'))
        ..._imports(path, parsed.unit, parsed.lineInfo),
      if (LayerRules.ownsNoAppearance(path))
        ..._rawStyle(path, parsed.unit, parsed.lineInfo),
      ..._orphanTodos(path, parsed.unit, parsed.lineInfo),
    ];
  }

  List<Violation> _orphanTodos(
    String path,
    CompilationUnit unit,
    LineInfo lines,
  ) {
    return [
      for (final offset in TodoFinder.orphansIn(unit))
        Violation(
          path: path,
          line: lines.getLocation(offset).lineNumber,
          rule: 'orphan-todo',
          message: 'TODO sem item de backlog; cite o BL-nnn ou abra um',
        ),
    ];
  }

  List<Violation> _imports(String path, CompilationUnit unit, LineInfo lines) {
    return [
      for (final directive in unit.directives.whereType<ImportDirective>())
        if (LayerRules.refusal(path, directive.uri.stringValue ?? '')
            case final reason?)
          Violation(
            path: path,
            line: lines.getLocation(directive.offset).lineNumber,
            rule: 'layer-imports',
            message: reason,
          ),
    ];
  }

  List<Violation> _rawStyle(String path, CompilationUnit unit, LineInfo lines) {
    final visitor = RawStyleVisitor(
      forbidden: {
        ...RawStyleVisitor.appearanceTypes,
        if (path.contains('/presentation/')) 'Duration',
      },
    );
    unit.accept(visitor);
    return [
      for (final (name, offset) in visitor.found)
        Violation(
          path: path,
          line: lines.getLocation(offset).lineNumber,
          rule: 'raw-style',
          message:
              '$name( fora do design system; peça um token ou um componente '
              'a packages/design_system',
        ),
    ];
  }
}
