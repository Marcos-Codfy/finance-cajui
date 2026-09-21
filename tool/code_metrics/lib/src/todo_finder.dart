import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';

/// Acha os `TODO` sem dono: comentário que promete trabalho sem citar o item
/// do `BACKLOG.md` em que esse trabalho está anotado.
///
/// Promessa solta em comentário é a que ninguém cumpre. Com o item citado, o
/// `TODO` vira ponteiro — e o que falta fazer continua num lugar só.
abstract final class TodoFinder {
  // Só a forma de promessa conta: a palavra seguida do dono entre parênteses
  // ou de dois-pontos. Citada numa explicação, como nesta, não promete nada.
  static final _todo = RegExp(r'\bTODO\s*[(:]');
  static final _backlogItem = RegExp(r'\bBL-\d{3}\b');

  /// A posição de cada `TODO` sem item do backlog em [unit].
  static List<int> orphansIn(CompilationUnit unit) {
    final offsets = <int>[];
    Token? token = unit.beginToken;
    while (token != null) {
      offsets.addAll(_orphansBefore(token));
      token = token.isEof ? null : token.next;
    }
    return offsets;
  }

  static Iterable<int> _orphansBefore(Token token) sync* {
    Token? comment = token.precedingComments;
    while (comment != null) {
      final text = comment.lexeme;
      if (_todo.hasMatch(text) && !_backlogItem.hasMatch(text)) {
        yield comment.offset;
      }
      comment = comment.next;
    }
  }
}
