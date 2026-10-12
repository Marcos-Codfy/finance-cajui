import 'package:domain/domain.dart';
import 'package:test/test.dart';

StatementLine _raw(
  String description, {
  StatementLineKind kind = StatementLineKind.expense,
  bool doubtful = false,
  String? category,
  Confidence confidence = Confidence.medium,
}) => StatementLine(
  occurredOn: LocalDate(2026, 10, 12),
  description: description,
  amount: const Money.fromCents(15000),
  kind: kind,
  doubtful: doubtful,
  categoryId: category,
  confidence: confidence,
);

LearnedAnswers _memory(
  String key, {
  LineTreatment? treatment,
  String? category,
}) => LearnedAnswers.of([
  LearnedAnswer(
    key: key,
    treatment: treatment,
    categoryId: category,
    definedAt: DateTime.utc(2026, 9),
  ),
]);

void main() {
  group('RN-1110 e RN-1116 · a resposta lembrada respeita o sentido', () {
    test('"é dinheiro que entrou" para o Pix recebido não faz o Pix '
        'enviado à mesma pessoa virar renda', () {
      final sent = StatementLineResolver.resolve(
        _raw('Pix para [NOME]'),
        original: 'PIX ENVIADO JOAO P SILVA 150,00',
        memory: _memory('pessoa:joao p silva', treatment: LineTreatment.income),
      );

      expect(sent.treatment, isNull);
      expect(sent.isIncome, isFalse);
      expect(sent.doubts, contains(LineDoubt.kind));
    });

    test('"é um gasto" para o Pix enviado não faz a devolução recebida '
        'virar despesa', () {
      final back = StatementLineResolver.resolve(
        _raw('Pix de [NOME]', kind: StatementLineKind.income),
        original: 'PIX RECEBIDO JOAO P SILVA 500,00',
        memory: _memory(
          'pessoa:joao p silva',
          treatment: LineTreatment.expense,
          category: 'home',
        ),
      );

      expect(back.isExpense, isFalse);
      expect(back.doubts, contains(LineDoubt.kind));
    });

    test('a fatura escrita na linha vence a memória (RN-756)', () {
      final bill = StatementLineResolver.resolve(
        _raw('Pagamento de fatura', kind: StatementLineKind.cardPayment),
        original: '08/10 PAGAMENTO DE FATURA 1.200,00',
        memory: _memory(
          MerchantBrand.keyOf('Pagamento de fatura'),
          treatment: LineTreatment.expense,
        ),
      );

      expect(bill.isLeftOut, isTrue);
    });

    test('"alguém da casa" vale nos dois sentidos', () {
      final memory = _memory(
        'pessoa:carla m souza',
        treatment: LineTreatment.household,
      );
      for (final (raw, original) in [
        (_raw('Pix para [NOME]'), 'PIX ENVIADO CARLA M SOUZA 150,00'),
        (
          _raw('Pix de [NOME]', kind: StatementLineKind.income),
          'PIX RECEBIDO CARLA M SOUZA 80,00',
        ),
      ]) {
        final line = StatementLineResolver.resolve(
          raw,
          original: original,
          memory: memory,
        );
        expect(line.treatment, LineTreatment.household, reason: original);
      }
    });
  });

  group('RN-1110 · Pix ou transferência sem ninguém reconhecido', () {
    test('o nome que o banco cortou vira pergunta', () {
      final line = StatementLineResolver.resolve(
        _raw('Pix enviado', category: 'other'),
        original: '05/10 PIX ENVIADO JOAO 30,00',
      );

      expect(line.doubts, contains(LineDoubt.kind));
    });

    test('Pix para uma loja com a categoria certa da IA não pergunta', () {
      final line = StatementLineResolver.resolve(
        _raw(
          'Mercado Boa Vista',
          category: 'groceries',
          confidence: Confidence.high,
        ),
        original: '05/10 PIX ENVIADO MERCADO BOA VISTA LTDA 80,00',
      );

      expect(line.isSure, isTrue);
    });

    test('a transferência entre contas escrita não pergunta (RN-759)', () {
      final line = StatementLineResolver.resolve(
        _raw('Transferência entre contas', kind: StatementLineKind.ownTransfer),
        original: '10/10 TRANSFERENCIA ENTRE CONTAS 500,00',
      );

      expect(line.isLeftOut, isTrue);
      expect(line.isSure, isTrue);
    });
  });

  group('RN-1116 · a linha sem nome não leva as outras junto', () {
    test('"Movimentação" com o texto original: a chave é a do texto', () {
      final amazon = StatementLineResolver.resolve(
        _raw('Movimentação'),
        original: '03/10 AMAZON.COM.BR MARKETPLACE 89,90',
      );
      final shopee = StatementLineResolver.resolve(
        _raw('Movimentação'),
        original: '04/10 SHOPEE.COM PAGAMENTO 42,00',
      );

      expect(amazon.merchantKey, isNot(shopee.merchantKey));
      expect(amazon.rememberable, isTrue);
    });

    test('sem o texto original, a resposta não é lembrada', () {
      final line = StatementLineResolver.resolve(_raw('Movimentação'));

      expect(line.rememberable, isFalse);
    });

    test('responder uma "Movimentação" não resolve a outra', () {
      final memory = _memory(
        StatementLineResolver.resolve(
          _raw('Movimentação'),
          original: '03/10 AMAZON.COM.BR MARKETPLACE 89,90',
        ).merchantKey,
        treatment: LineTreatment.ignore,
      );
      final other = StatementLineResolver.resolve(
        _raw('Movimentação', category: 'home'),
        original: '04/10 SHOPEE.COM PAGAMENTO 42,00',
        memory: memory,
      );

      expect(other.treatment, isNull);
    });
  });

  test('RN-1117 · a chave do conteúdo sai do texto lido, e não da descrição '
      'da IA, que muda de uma leitura para outra', () {
    const original = '02/10 MP*PADARIA BOA VISTA 18,50';
    final first = StatementLineResolver.resolve(
      _raw('Padaria Boa Vista'),
      original: original,
    );
    final again = StatementLineResolver.resolve(
      _raw('Padaria Boavista'),
      original: original,
    );

    expect(first.contentKey, again.contentKey);
  });

  group('RN-1110 · a entrada só é certa com palavra clara', () {
    test('TED recebida de empresa: dinheiro que entrou, sem perguntar', () {
      final salary = StatementLineResolver.resolve(
        _raw('Empresa Exemplo', kind: StatementLineKind.income),
        original: '01/10 TED RECEBIDA EMPRESA EXEMPLO LTDA 3.120,00',
      );

      expect(salary.isIncome, isTrue);
      expect(salary.isSure, isTrue);
    });

    test('estorno, resgate e pagamento recebido da fatura não são renda '
        'certa', () {
      for (final original in [
        '05/10 ESTORNO COMPRA LOJA ESTRELA 89,90',
        '06/10 RESGATE POUPANCA 500,00',
        '10/10 PAGAMENTO RECEBIDO 1.200,00',
      ]) {
        final line = StatementLineResolver.resolve(
          _raw('Entrada', kind: StatementLineKind.income),
          original: original,
        );
        expect(line.doubts, contains(LineDoubt.kind), reason: original);
      }
    });
  });

  group('RN-1111 · a parcela de compra de outro mês', () {
    test('a marca de parcela na linha', () {
      final sofa = InstallmentMark.of('05/10 SOFA LOJA MOVEIS 03/10 300,00')!;

      expect((sofa.number, sofa.total), (3, 10));
      expect(InstallmentMark.of('PARC 2/5 GELADEIRA 450,00')!.number, 2);
      expect(InstallmentMark.of('05/10 COMPRA MERCADO 05/10 50,00'), isNull);
      expect(InstallmentMark.of('05/10 PADARIA BOA VISTA 8,50'), isNull);
    });

    test('a parcela 3 de 10 vira pergunta; a primeira, compra do mês', () {
      final third = StatementLineResolver.resolve(
        _raw('Loja Móveis', category: 'home', confidence: Confidence.high),
        original: '05/10 SOFA LOJA MOVEIS 03/10 300,00',
      );
      final first = StatementLineResolver.resolve(
        _raw('Loja Móveis', category: 'home', confidence: Confidence.high),
        original: '05/10 SOFA LOJA MOVEIS 01/10 300,00',
      );

      expect(third.doubts, {LineDoubt.installment});
      expect(third.installment!.total, 10);
      expect(first.isSure, isTrue);
    });
  });
}
