import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:server/src/assistant/assistant_action.dart';

/// O que uma ferramenta devolveu: o resultado, em JSON, que volta ao modelo
/// — e, quando ela mexeu no livro, a ação para o app saber.
@immutable
final class ToolOutcome {
  const new _(this.result, {this.action});

  /// Deu certo, com [result]; [action] quando o livro mudou.
  const new done(Map<String, Object?> result, {AssistantAction? action})
    : this._(result, action: action);

  /// Não deu, pelo [reason]. O modelo lê o motivo e decide o que fazer.
  new failed(String reason) : this._({'erro': reason});

  /// O resultado, como o modelo o recebe.
  final Map<String, Object?> result;

  /// A mudança no livro, se houve.
  final AssistantAction? action;

  /// O resultado em texto, que é o que volta na mensagem da ferramenta.
  String get json => jsonEncode(result);
}
