import 'dart:convert';
import 'dart:typed_data';

import 'package:domain/domain.dart';
import 'package:server/src/ai/ai_receipt_classifier.dart';
import 'package:server/src/ai/ai_statement_lines.dart';
import 'package:server/src/ai/ai_suggestion.dart';
import 'package:server/src/ai/chat_reply.dart';
import 'package:server/src/ai/circuit_breaker.dart';
import 'package:test/test.dart';

import 'support/receipt_samples.dart';
import 'support/tool_chat_client.dart';

/// Uma página de extrato: para o servidor, basta a assinatura de JPEG.
final Uint8List _page = Uint8List.fromList([
  0xFF, 0xD8, 0xFF, 0xE0, //
  ...List.filled(64, 3),
]);

const _header = 'EXTRATO CONTA CORRENTE\nSETEMBRO 2026';

ClassificationRequest _request({String text = _header, bool withPage = true}) =>
    ClassificationRequest(
      text: ReceiptText.clean(text),
      categories: const [sampleGroceries, sampleRent],
      today: LocalDate(2026, 9, 20),
      images: withPage ? [_page] : const [],
    );

Future<EntryProposal> _read(
  List<Object?> lines, {
  ClassificationRequest? request,
}) async {
  final answer = {
    'documentKind': 'statement',
    'confidence': 0.8,
    'description': 'Extrato de setembro',
    'lines': lines,
  };
  final classifier = AiReceiptClassifier(
    client: ToolChatClient([
      ChatReply(
        content: jsonEncode(answer),
        promptTokens: 2400,
        completionTokens: 400,
      ),
    ]),
    budget: await sampleBudget(),
    breaker: CircuitBreaker(),
  );
  return await classifier.classify(request ?? _request());
}

Map<String, Object?> _line(
  String day,
  int cents, {
  String description = 'Mercado Boa Compra',
  String kind = 'expense',
  String? categoryId,
}) => {
  'occurredOn': '2026-09-$day',
  'amountCents': cents,
  'description': description,
  'kind': kind,
  'categoryId': ?categoryId,
};

void main() {
  group('RN-707 · o extrato vira linhas para marcar', () {
    test('cada movimentação vira uma linha, com o valor positivo e o '
        'sentido no tipo', () async {
      final proposal = await _read([
        _line('03', -4590, categoryId: 'groceries'),
        _line('05', 320000, description: 'Salário', kind: 'income'),
        _line('10', -150000, description: 'Fatura', kind: 'cardPayment'),
        _line('12', -50000, description: 'Poupança', kind: 'ownTransfer'),
      ]);

      expect(proposal.isStatement, isTrue);
      expect(proposal.documentKind.value, DocumentKind.statement);
      final lines = proposal.lines;
      expect(lines, hasLength(4));
      expect(lines.first.amount, const Money.fromCents(4590));
      expect(lines.first.categoryId, 'groceries');
      expect(lines.first.occurredOn, LocalDate(2026, 9, 3));
      expect(lines.map((line) => line.kind), [
        StatementLineKind.expense,
        StatementLineKind.income,
        StatementLineKind.cardPayment,
        StatementLineKind.ownTransfer,
      ]);
    });

    test('linha que não passa nas conferências cai fora sozinha, sem levar '
        'as outras', () async {
      final proposal = await _read([
        _line('03', -4590),
        _line('25', -1000), // depois de hoje
        _line('04', 0),
        _line('06', 200000000), // acima do teto
        'texto solto',
        _line('07', -2500, categoryId: 'inventada', kind: 'outra'),
      ]);

      expect(proposal.lines, hasLength(2));
      final last = proposal.lines.last;
      expect(last.amount, const Money.fromCents(2500));
      expect(last.categoryId, isNull);
      expect(last.kind, StatementLineKind.expense);
      expect(last.doubtful, isTrue);
    });

    test('descrição com contato não chega à tela: vira "Movimentação" '
        '(RN-775)', () async {
      final proposal = await _read([
        _line('03', -4590, description: 'Ligue 0800 para regularizar'),
        _line('04', -1000),
      ]);

      expect(proposal.lines.first.description, AiStatementLines.unnamed);
    });

    test(
      'RN-774 · sem a foto, valor que não está no texto é inventado',
      () async {
        final proposal = await _read(
          [_line('03', -4590), _line('04', -9999), _line('04', -1200)],
          request: _request(
            text:
                '$_header\n03/09/2026 MERCADO R\$ 45,90\n'
                r'04/09/2026 PADARIA R$ 12,00',
            withPage: false,
          ),
        );

        expect(proposal.lines.map((line) => line.amount.cents), [4590, 1200]);
      },
    );

    test('no máximo ${AiStatementLines.maxLines} linhas por extrato', () async {
      final proposal = await _read([
        for (var cents = 100; cents < 140; cents++) _line('03', -cents),
      ]);

      expect(proposal.lines, hasLength(AiStatementLines.maxLines));
    });

    test(
      '"extrato" sem nenhuma linha aproveitável segue como comprovante',
      () async {
        final proposal = await _read([_line('25', -1000), 'nada']);

        expect(proposal.isStatement, isFalse);
        expect(proposal.documentKind.value, isNot(DocumentKind.statement));
      },
    );

    test('uma linha só não é extrato: é comprovante lido torto, ou foto '
        'querendo esconder uma compra (INJ-07)', () async {
      final proposal = await _read([
        _line('03', -8640, kind: 'cardPayment', description: 'Fatura'),
      ]);

      expect(proposal.isStatement, isFalse);
    });
  });

  group('RN-756 a RN-759 · o tipo de cada linha', () {
    test('a palavra escrita na linha manda, diga a IA o que disser', () async {
      final proposal = await _read([
        _line('03', -150000, description: 'Pgto fatura Nubank'),
        _line('05', 12000, description: 'Pix recebido Maria'),
        _line('06', -10000, description: 'Saque 24h'),
      ]);

      expect(proposal.lines.map((line) => line.kind), [
        StatementLineKind.cardPayment,
        StatementLineKind.income,
        StatementLineKind.ownTransfer,
      ]);
      expect(proposal.lines.any((line) => line.doubtful), isFalse);
    });

    test(
      'fatura e transferência que só a IA viu ficam em dúvida (RN-757)',
      () async {
        final proposal = await _read([
          _line(
            '03',
            -150000,
            description: 'Nu Pagamentos',
            kind: 'cardPayment',
          ),
          _line('04', -50000, description: 'Joao Silva', kind: 'ownTransfer'),
          _line('05', -1500, description: 'Padaria Central'),
        ]);

        expect(proposal.lines.map((line) => line.doubtful), [
          true,
          true,
          false,
        ]);
      },
    );

    test(
      'linha sem tipo é despesa em dúvida: aparece, mas nunca vem marcada',
      () async {
        final proposal = await _read([
          {
            'occurredOn': '2026-09-03',
            'amountCents': 12000,
            'description': 'Movimento',
          },
          _line('04', -1500),
        ]);

        expect(proposal.lines.first.kind, StatementLineKind.expense);
        expect(proposal.lines.first.doubtful, isTrue);
      },
    );

    test('RN-111 · no extrato do vale, toda linha é vale', () async {
      final proposal = await _read([
        _line('03', -4590),
        _line('01', 80000, kind: 'income'),
      ], request: _request(text: 'ALELO ALIMENTACAO\nEXTRATO DO CARTAO'));

      expect(
        proposal.lines.map((line) => line.paymentKind),
        everyElement(PaymentMethodKind.mealVoucher),
      );
    });

    test('valor infinito não derruba a leitura', () {
      final suggestion = AiSuggestion.parse(
        '{"documentKind": "statement", "amountCents": 1e400, "installments": '
        '1e400, "lines": [{"occurredOn": "2026-09-03", "amountCents": 1e400, '
        '"description": "x", "kind": "expense"}]}',
        _request(),
      );

      expect(suggestion, isNotNull);
      expect(suggestion!.amount, isNull);
      expect(suggestion.lines, isEmpty);
    });
  });
}
