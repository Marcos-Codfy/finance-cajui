import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:server/src/ai/chat_reply.dart';
import 'package:server/src/auth/session_scope.dart';
import 'package:test/test.dart';

import 'support/statement_server.dart';
import 'support/tool_chat_client.dart';

const _page = StatementPageRequest(
  lines: statementLines,
  page: 1,
  pageCount: 1,
);

void main() {
  group('RN-1106 · RN-1107 · o que a IA não fica sabendo', () {
    test(
      'o nome do Pix e o nome da casa vão mascarados, linha a linha',
      () async {
        final client = ToolChatClient([aiPage(const [])]);
        final app = await statementServer(client);
        await postTo(app, '/v1/facts', {
          'id': 'casa-1',
          'type': DeviceFact.householdNamed,
          'payload': HouseholdCodec.encode(
            HouseholdNames(
              names: const ['Bianca Souza Lima'],
              definedAt: DateTime.utc(2026, 9),
            ),
          ),
        });

        await readPage(
          app,
          lines: [...statementLines, '14/09 DEPOSITO BIANCA SOUZA LIMA 200,00'],
        );

        final asked = askedOf(client);
        expect(asked, isNot(contains('JOAO P SILVA')));
        expect(asked, isNot(contains('MARIA DE SOUZA')));
        expect(asked, isNot(contains('BIANCA')));
        expect(asked, contains('[3] 05/09 PIX ENVIADO [NOME] 150,00'));
        expect(asked, contains('[7] 14/09 DEPOSITO [NOME] 200,00'));
      },
    );

    test(
      'exemplo que fala de pessoa é descartado, mesmo vindo do celular',
      () async {
        final client = ToolChatClient([aiPage(const [])]);

        await readPage(
          await statementServer(client),
          examples: const {
            'pessoa:joao p silva': 'groceries',
            'padaria boa vista': 'groceries',
          },
        );

        expect(askedOf(client), contains('padaria boa vista'));
        expect(askedOf(client), isNot(contains('pessoa:')));
      },
    );
  });

  group('quando a página não sai', () {
    test('resposta fora do esquema é E-AI-04 com 502: o celular tenta a '
        'página de novo', () async {
      final client = ToolChatClient([
        const ChatReply(
          content: 'não é JSON',
          promptTokens: 100,
          completionTokens: 10,
        ),
      ]);

      final (status, body) = await postTo(
        await statementServer(client),
        readPartPath,
        _page.toJson(),
      );

      expect(status, 502);
      expect(ApiError.fromJson(body).code, ErrorCode.ai04);
    });

    test('sem a credencial da IA, toda página recebe E-AI-01', () async {
      final (status, body) = await postTo(
        await statementServer(null),
        readPartPath,
        _page.toJson(),
      );

      expect(status, 503);
      expect(ApiError.fromJson(body).code, ErrorCode.ai01);
    });

    test('RN-1100 · a web, que só consulta, não lê extrato', () async {
      final app = await statementServer(ToolChatClient([aiPage(const [])]));
      final web = app.sessions.open(
        'consulta',
        scope: SessionScope.webReadOnly,
      );

      final (status, _) = await postTo(
        app,
        readPartPath,
        _page.toJson(),
        token: web,
      );

      expect(status, 403);
    });

    test('imagem que não é imagem é pedido malformado (E-REQ-01)', () async {
      final client = ToolChatClient([aiPage(const [])]);
      final json = {..._page.toJson(), 'image': 'bm90IGFuIGltYWdl'};

      final (status, body) = await postTo(
        await statementServer(client),
        readPartPath,
        json,
      );

      expect(status, 400);
      expect(ApiError.fromJson(body).code, ErrorCode.req01);
      expect(client.conversations, isEmpty);
    });
  });
}
