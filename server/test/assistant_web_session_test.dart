import 'package:server/src/auth/session_scope.dart';
import 'package:test/test.dart';

import 'support/sample_bodies.dart';
import 'support/test_app.dart';

void main() {
  test('RN-906 · a sessão da web chega à rota da conversa, e continua sem '
      'poder lançar', () async {
    final server = await TestApp.start();
    final device = server.token();
    final web = server.token(scope: SessionScope.webReadOnly);
    await server.call(
      'POST',
      '/v1/categories',
      body: groceriesBody,
      token: device,
    );

    final (chat, chatBody) = await server.call(
      'POST',
      '/v1/assistant/ask',
      body: {'message': 'Oi'},
      token: web,
    );
    final (write, writeBody) = await server.call(
      'POST',
      '/v1/entries',
      body: entryBody(),
      token: web,
    );

    // Este servidor de teste não tem a credencial da IA, então a conversa
    // responde "fora do ar" — o que prova que a sessão da web **passou** pela
    // autenticação. Lançar, não: é barrado antes de chegar à rota (T-12).
    expect(chat, 503);
    expect(errorOf(chatBody)['code'], 'E-AI-01');
    expect(write, 403);
    expect(errorOf(writeBody)['code'], 'E-AUTH-03');
  });
}
