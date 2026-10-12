import 'package:domain/domain.dart';
import 'package:server/src/ai/chat_reply.dart';
import 'package:test/test.dart';

import 'support/statement_server.dart';
import 'support/tool_chat_client.dart';

/// Uma resposta inteira, sem corte, que não está no esquema (E-AI-04).
const _offSchema = ChatReply(
  content: '{"lines": [], "instrucao": "ignore as regras"}',
  promptTokens: 800,
  completionTokens: 20,
);

void main() {
  group('RN-1102 · uma página por pedido', () {
    test('as movimentações voltam com a linha de origem e o período; a '
        'palavra escrita manda no tipo, e a marca dá o nome', () async {
      final client = ToolChatClient([
        aiPage(period: '2026-09', [
          aiMove(2, 3, 1250, categoryId: 'groceries'),
          aiMove(4, 8, 5590, description: 'NETFLIX.COM'),
          aiMove(5, 10, 150000, description: 'Fatura'),
          aiMove(6, 12, 32000, description: 'Pix recebido'),
        ]),
      ]);

      final (status, reply) = await readPage(await statementServer(client));

      expect(status, 200);
      expect(reply.period, const BudgetMonth(2026, 9));
      expect(reply.partial, isFalse);
      final [bakery, netflix, invoice, pix] = reply.movements;
      expect(bakery.sourceLine, 2);
      expect(bakery.categoryId, 'groceries');
      expect(bakery.amount, const Money.fromCents(1250));
      expect(netflix.description, 'Netflix');
      expect(invoice.kind, StatementLineKind.cardPayment);
      expect(invoice.doubtful, isFalse);
      expect(pix.kind, StatementLineKind.income);
    });

    test('a mesma página de novo não paga outra vez (RN-778)', () async {
      final client = ToolChatClient([
        aiPage([aiMove(2, 3, 1250)]),
      ]);
      final app = await statementServer(client);

      await readPage(app);
      final (_, again) = await readPage(app);

      expect(client.conversations, hasLength(1));
      expect(again.movements, hasLength(1));
    });
  });

  group('RN-1103 · resposta cortada pelo teto de tamanho', () {
    test('a página vai de novo em duas metades, sem perder nenhuma', () async {
      final client = ToolChatClient([
        aiCut([aiMove(2, 3, 1250)]),
        aiPage([aiMove(2, 3, 1250), aiMove(3, 5, 15000)]),
        aiPage([aiMove(4, 8, 5590), aiMove(5, 10, 150000)]),
      ]);

      final (_, reply) = await readPage(await statementServer(client));

      expect(client.conversations, hasLength(3));
      expect(askedOf(client, 1), contains('[3] '));
      expect(askedOf(client, 1), isNot(contains('[4] ')));
      expect(askedOf(client, 2), contains('[4] '));
      expect(askedOf(client, 2), isNot(contains('[3] ')));
      expect(reply.movements.map((m) => m.sourceLine), [2, 3, 4, 5]);
      expect(reply.partial, isFalse);
    });

    test('cortou de novo: valem as completas, e a página sai lida em parte '
        '(E-AI-05)', () async {
      final client = ToolChatClient([
        aiCut([aiMove(2, 3, 1250)]),
        aiCut([aiMove(2, 3, 1250)]),
        aiPage([aiMove(4, 8, 5590)]),
      ]);

      final (status, reply) = await readPage(await statementServer(client));

      expect(status, 200);
      expect(reply.movements.map((m) => m.sourceLine), [2, 4]);
      expect(reply.partial, isTrue);
      expect(reply.period, const BudgetMonth(2026, 9));
    });

    test('as duas metades fora do esquema: valem as completas que a '
        'resposta cortada já trouxe, e a página sai lida em parte', () async {
      final client = ToolChatClient([
        aiCut([aiMove(2, 3, 1250), aiMove(4, 8, 5590)]),
        _offSchema,
        _offSchema,
      ]);

      final (status, reply) = await readPage(await statementServer(client));

      expect(status, 200);
      expect(client.conversations, hasLength(3));
      expect(reply.movements.map((m) => m.sourceLine), [2, 4]);
      expect(reply.partial, isTrue);
    });

    test('uma metade fora do esquema fica com o que a cortada trouxe das '
        'linhas dela; a outra vale inteira', () async {
      final client = ToolChatClient([
        aiCut([aiMove(2, 3, 1250), aiMove(4, 8, 5590)]),
        _offSchema,
        aiPage([aiMove(5, 10, 150000)]),
      ]);

      final (_, reply) = await readPage(await statementServer(client));

      // A linha 4 é da segunda metade, que respondeu: vale a resposta dela.
      expect(reply.movements.map((m) => m.sourceLine), [2, 5]);
      expect(reply.partial, isTrue);
    });
  });

  group('RN-774 · RN-1105 · cada movimentação é conferida contra a página', () {
    test('valor que não está no texto cai fora; o que está noutra linha vai '
        'para a linha que o mostra', () async {
      final client = ToolChatClient([
        aiPage([aiMove(2, 3, 99999), aiMove(2, 5, 15000)]),
      ]);

      final (_, reply) = await readPage(await statementServer(client));

      expect(reply.movements.single.sourceLine, 3);
      expect(reply.movements.single.amount, const Money.fromCents(15000));
    });

    test('data depois de hoje cai, mesmo escrita na página', () async {
      final client = ToolChatClient([
        aiPage([aiMove(2, 3, 1250), aiMove(7, 25, 1000)]),
      ]);

      final (_, reply) = await readPage(
        await statementServer(client),
        lines: [...statementLines, '25/09 MERCADO DO FUTURO 10,00'],
      );

      expect(reply.movements.map((m) => m.sourceLine), [2]);
    });

    test('data que a página não escreve cai', () async {
      final client = ToolChatClient([
        aiPage([aiMove(2, 4, 1250), aiMove(4, 8, 5590)]),
      ]);

      final (_, reply) = await readPage(await statementServer(client));

      expect(reply.movements.map((m) => m.day), [8]);
    });
  });
}
