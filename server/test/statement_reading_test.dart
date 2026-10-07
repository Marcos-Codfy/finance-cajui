import 'dart:convert';
import 'dart:typed_data';

import 'package:domain/domain.dart';
import 'package:server/src/ai/ai_receipt_classifier.dart';
import 'package:server/src/ai/ai_statement_lines.dart';
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
    });

    test('descrição com contato não chega à tela: vira "Movimentação" '
        '(RN-775)', () async {
      final proposal = await _read([
        _line('03', -4590, description: 'Ligue 0800 para regularizar'),
      ]);

      expect(proposal.lines.single.description, AiStatementLines.unnamed);
    });

    test(
      'RN-774 · sem a foto, valor que não está no texto é inventado',
      () async {
        final proposal = await _read(
          [_line('03', -4590), _line('04', -9999)],
          request: _request(
            text:
                '$_header\n03/09/2026 MERCADO R\$ 45,90\n'
                '04/09/2026 PADARIA',
            withPage: false,
          ),
        );

        expect(proposal.lines.single.amount, const Money.fromCents(4590));
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
  });
}
