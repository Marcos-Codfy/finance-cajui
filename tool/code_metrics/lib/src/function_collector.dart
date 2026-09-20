import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Uma função encontrada no arquivo: o nome, o nó inteiro e o corpo.
typedef FoundFunction = ({String name, AstNode node, AstNode body});

/// Junta tudo o que tem corpo de função: funções soltas, métodos,
/// construtores e funções locais. Função anônima não entra: ela já é medida
/// como parte de quem a contém.
class FunctionCollector extends RecursiveAstVisitor<void> {
  /// As funções encontradas, na ordem do arquivo.
  final List<FoundFunction> found = [];

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    found.add((
      name: node.name.lexeme,
      node: node,
      body: node.functionExpression.body,
    ));
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    found.add((name: node.name.lexeme, node: node, body: node.body));
    super.visitMethodDeclaration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    found.add((name: 'construtor', node: node, body: node.body));
    super.visitConstructorDeclaration(node);
  }
}
