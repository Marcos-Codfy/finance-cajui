import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Acha os lugares em que o código monta aparência na mão: `Color(0xFF…)`,
/// `TextStyle(…)`, `Color.fromARGB(…)`.
///
/// A análise é só sintática, então `Color(…)` sem `const` chega como chamada
/// de método e com `const` como criação de instância. Os dois caminhos são
/// conferidos.
class RawStyleVisitor extends RecursiveAstVisitor<void> {
  /// Cria o visitante que procura os tipos de [forbidden].
  new({required this.forbidden});

  /// Os tipos que definem aparência em qualquer lugar do app.
  static const appearanceTypes = {'Color', 'TextStyle'};

  /// Os nomes de tipo cuja criação é reprovada.
  final Set<String> forbidden;

  /// O nome do tipo e a posição de cada ocorrência.
  final List<(String, int)> found = [];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final name = node.constructorName.type.name.lexeme;
    if (forbidden.contains(name)) found.add((name, node.offset));
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    final name = target is SimpleIdentifier
        ? target.name
        : node.methodName.name;
    final isCreation = target == null || target is SimpleIdentifier;
    if (isCreation && forbidden.contains(name)) found.add((name, node.offset));
    super.visitMethodInvocation(node);
  }
}
