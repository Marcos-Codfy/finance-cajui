import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:server/src/ai/classification_prompt.dart';
import 'package:server/src/auth/secure_random.dart';

/// A mesma captura não paga duas vezes (RN-778): a resposta válida da IA é
/// guardada e reaproveitada quando o mesmo comprovante volta.
///
/// A chave é o **resumo** do texto já mascarado, junto com a versão das
/// instruções e as listas enviadas — mudou a lista de categorias ou o que o
/// app aprendeu, a resposta antiga deixa de valer. Nem o texto nem o resumo
/// reversível dele ficam guardados: só o SHA-256 e a resposta, que já passou
/// pela validação de esquema.
///
/// Vive na memória do processo. Reiniciar o servidor custa, no máximo, uma
/// chamada a mais por comprovante reaberto.
final class SuggestionCache {
  /// Cria o cache, com lugar para [capacity] respostas.
  new({this.capacity = 200});

  /// Quantas respostas cabem. Cheio, sai a mais antiga.
  final int capacity;

  // `Map` do Dart guarda a ordem de inserção: o primeiro é o mais antigo.
  final Map<String, String> _replies = {};

  /// A chave de [redacted] nas listas de [request].
  static String keyOf(String redacted, ClassificationRequest request) {
    final lists = jsonEncode({
      'v': ClassificationPrompt.version,
      'categories': [for (final category in request.categories) category.id],
      'examples': request.learnedRules,
    });
    return SecureRandom.hash('$lists\n$redacted');
  }

  /// A resposta guardada para [key], ou `null`.
  String? operator [](String key) => _replies[key];

  /// Guarda [reply] — só chamado com resposta que passou na validação.
  void operator []=(String key, String reply) {
    _replies.remove(key);
    _replies[key] = reply;
    if (_replies.length > capacity) _replies.remove(_replies.keys.first);
  }
}
