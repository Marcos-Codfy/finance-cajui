import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Mede a profundidade de blocos de controle dentro de uma função.
///
/// Conta `if`, `for`, `while`, `do`, `switch` e `try`. Não conta função
/// anônima nem coleção literal: a árvore de widgets do Flutter é aninhada por
/// natureza, e o que a regra quer conter é lógica dentro de lógica.
class NestingVisitor extends RecursiveAstVisitor<void> {
  int _depth = 0;

  /// A maior profundidade encontrada.
  int deepest = 0;

  /// O nó em que a maior profundidade foi atingida.
  AstNode? deepestNode;

  void _nested(AstNode node, void Function() visitChildren) {
    _depth++;
    if (_depth > deepest) {
      deepest = _depth;
      deepestNode = node;
    }
    visitChildren();
    _depth--;
  }

  /// `else if` é uma alternativa do mesmo nível, não um bloco mais fundo.
  @override
  void visitIfStatement(IfStatement node) {
    node.expression.accept(this);
    _nested(node, () => node.thenStatement.accept(this));
    final otherwise = node.elseStatement;
    if (otherwise is IfStatement) {
      otherwise.accept(this);
    } else if (otherwise != null) {
      _nested(node, () => otherwise.accept(this));
    }
  }

  @override
  void visitForStatement(ForStatement node) =>
      _nested(node, () => super.visitForStatement(node));

  @override
  void visitWhileStatement(WhileStatement node) =>
      _nested(node, () => super.visitWhileStatement(node));

  @override
  void visitDoStatement(DoStatement node) =>
      _nested(node, () => super.visitDoStatement(node));

  @override
  void visitSwitchStatement(SwitchStatement node) =>
      _nested(node, () => super.visitSwitchStatement(node));

  @override
  void visitTryStatement(TryStatement node) =>
      _nested(node, () => super.visitTryStatement(node));
}
