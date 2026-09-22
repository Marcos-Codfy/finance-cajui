import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/assistant/presentation/assistant_reply_view.dart';
import 'package:flutter_test/flutter_test.dart';

/// Nenhum código do catálogo pode derrubar a tela que deveria contá-lo.
///
/// Já aconteceu duas vezes: `{fila}` no `E-APP-01` derrubou a conversa com
/// erro de asserção, e `{ação}` no `E-SRV-01` faria o mesmo. O servidor
/// devolve o código que quiser — a tela tem de aguentar qualquer um.
void main() {
  test('o assistente preenche toda chave de todo erro do catálogo', () {
    final quebrados = <String>[];

    for (final code in ErrorCode.values) {
      final text = AssistantReplyView.textOf(code, retryAfterSeconds: 30);
      for (final phrase in [text.message, ...text.actions]) {
        if (phrase.contains('{') || phrase.contains('…')) {
          quebrados.add('${code.code}: $phrase');
        }
      }
    }

    expect(quebrados, isEmpty, reason: quebrados.join('\n'));
  });
}
