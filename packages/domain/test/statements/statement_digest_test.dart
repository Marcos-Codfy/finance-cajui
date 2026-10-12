import 'package:domain/domain.dart';
import 'package:test/test.dart';

String _brl(String digits) => 'R\$${MoneyFormat.nbsp}$digits';

ResolvedLine _line(
  String name,
  int cents, {
  int day = 5,
  String? category = 'groceries',
  StatementLineKind kind = StatementLineKind.expense,
  PaymentMethodKind? paidBy,
  LineTreatment? treatment,
  Set<LineDoubt> doubts = const {},
}) => ResolvedLine(
  line: StatementLine(
    occurredOn: LocalDate(2026, 10, day),
    description: name,
    amount: Money.fromCents(cents),
    kind: kind,
    categoryId: doubts.contains(LineDoubt.category) ? null : category,
    paymentKind: paidBy,
  ),
  merchantKey: name.toLowerCase(),
  treatment: treatment,
  doubts: doubts,
);

void main() {
  group('RN-1113 · os blocos de gasto certo, por categoria', () {
    test('agrupa, ordena do maior para o menor e soma por moeda', () {
      final digest = StatementDigest.of([
        _line('Padaria Boa Vista', 800, category: 'bakery'),
        _line('Assaí', 41230),
        _line('Atacadão', 38000),
        _line('Assaí', 24000, paidBy: PaymentMethodKind.mealVoucher),
      ]);

      expect(digest.blocks.map((b) => b.categoryId), ['groceries', 'bakery']);
      final groceries = digest.blocks.first;
      expect(groceries.lines, [1, 2, 3], reason: 'do maior para o menor');
      expect(groceries.cash, const Money.fromCents(79230));
      expect(groceries.voucher, const Money.fromCents(24000));
      expect(digest.rankedCategories, ['groceries', 'bakery']);
    });

    test('o que é dúvida, o que já está no Cajui e o que a pessoa tirou não '
        'entram nos blocos', () {
      final digest = StatementDigest.of(
        [
          _line('Assaí', 41230),
          _line('Loja Estrela', 15000, doubts: {LineDoubt.category}),
          _line('Atacadão', 38000),
          _line('Padaria', 800, category: 'bakery'),
        ],
        alreadyThere: {2},
        skipped: {3},
      );

      expect(digest.blocks.single.lines, [0]);
      expect(digest.questions, [1]);
      expect(digest.ready, [0]);
    });
  });

  group('RN-1112 · o resumo que abre a conversa', () {
    final digest = StatementDigest.of(
      [
        _line('Assaí', 41230, day: 1),
        _line('Padaria', 800, day: 3, category: 'bakery'),
        _line(
          'Salário',
          312000,
          kind: StatementLineKind.income,
          category: null,
        ),
        _line(
          'Pagamento de fatura',
          120000,
          day: 8,
          kind: StatementLineKind.cardPayment,
          category: null,
        ),
        _line(
          'Pix para Beatriz',
          50000,
          day: 9,
          treatment: LineTreatment.household,
        ),
        _line('Loja Estrela', 15000, day: 20, doubts: {LineDoubt.category}),
        _line('Farmácia', 3000, day: 31, category: 'health'),
      ],
      alreadyThere: {6},
    );

    test('diz o período, os gastos, as entradas, o que não conta, o que já '
        'estava e as dúvidas — sem somar moedas', () {
      expect(
        StatementWords.summary(digest),
        'Li 7 movimentações de 1 a 31 de outubro. '
        '3 gastos, ${_brl('570,30')}; 1 entrada, ${_brl('3.120,00')}. '
        '1 pagamento de fatura e 1 transferência entre contas não contam. '
        '1 já estava no Cajui. 1 ficou em dúvida: pergunto depois dos blocos.',
      );
    });

    test('RN-944 · nenhuma frase fere o guia de voz', () {
      final texts = [
        StatementWords.summary(digest),
        for (final block in digest.blocks)
          StatementWords.block(block, 'Mercado', digest.lines),
        StatementWords.done(recorded: 58),
        StatementWords.done(recorded: 0),
        StatementWords.done(recorded: 56, already: 2, refused: 1),
        StatementWords.already(10),
        StatementWords.whichCard,
        StatementWords.installments(digest),
        StatementWords.ready(58),
        StatementWords.ready(0),
        StatementWords.opening,
        StatementWords.saving,
        StatementWords.undone(58),
        StatementWords.pages(read: 20, total: 24, failed: [4], partial: [2])!,
      ];
      for (final text in texts) {
        expect(VoiceGuide.violations(text), isEmpty, reason: text);
        expect(text, isNot(contains('!')), reason: text);
      }
    });
  });

  test('RN-1113 · o bloco diz até três nomes e "e mais N"', () {
    final lines = [
      for (final name in ['Assaí', 'Atacadão', 'Pão de Açúcar', 'Dia', 'Extra'])
        _line(name, 10000),
    ];
    final digest = StatementDigest.of(lines);

    expect(
      StatementWords.block(digest.blocks.single, 'Mercado', lines),
      'Mercado — 5 compras, ${_brl('500,00')}: Assaí, Atacadão, '
      'Pão de Açúcar e mais 2. Confere?',
    );
  });

  test('RN-1111 · as parcelas saem dos gastos e das dúvidas, e viram uma '
      'pergunta só', () {
    final digest = StatementDigest.of([
      _line('Assaí', 41230),
      _line('Loja Móveis', 30000, doubts: {LineDoubt.installment}),
    ]);

    expect(digest.installments, [1]);
    expect(digest.questions, isEmpty);
    expect(digest.spending.count, 1);
    expect(
      StatementWords.installments(digest),
      '1 parcela de compras de outros meses, ${_brl('300,00')} — lanço como '
      'gasto deste mês?',
    );
  });

  test('RN-1118 · o fim diz quantos entraram, quantos já estavam e quantos '
      'não entraram', () {
    expect(
      StatementWords.done(recorded: 56, already: 2, refused: 1),
      'Lancei 56 lançamentos. 2 já estavam no Cajui e não entraram de novo. '
      '1 não entrou: o motivo vem abaixo. Se algo não estiver certo, dá para '
      'desfazer tudo.',
    );
    expect(StatementWords.done(recorded: 0), 'Nada novo para lançar.');
  });

  test('RN-1101 a RN-1103 · as páginas que ficaram de fora são ditas', () {
    expect(StatementWords.pages(read: 7, total: 7), isNull);
    expect(
      StatementWords.pages(read: 7, total: 7, beyond: 12),
      'Passou de 400 movimentações: as últimas 12 ficaram de fora.',
    );
    expect(
      StatementWords.pages(read: 20, total: 24, failed: [4, 6], partial: [2]),
      'Li as páginas 1 a 20 de 24. As páginas 4 e 6 não deram para ler. '
      'A página 2 foi lida em parte.',
    );
  });

  group('RN-1114 · a pergunta de cada dúvida', () {
    test('o tipo vem antes da categoria, com as quatro saídas', () {
      final line = _line(
        'Pix para João P Silva',
        15000,
        day: 12,
        doubts: {LineDoubt.kind, LineDoubt.category},
      );
      final question = StatementQuestion.of(0, line, ranked: const []);

      expect(question, isA<KindQuestion>());
      expect((question! as KindQuestion).options, [
        LineTreatment.expense,
        LineTreatment.household,
        LineTreatment.ownAccount,
        LineTreatment.ignore,
      ]);
      expect(
        StatementWords.question(question, line),
        'Pix para João P Silva, ${_brl('150,00')}, em 12/10. O que foi?',
      );
    });

    test('a entrada pergunta se é dinheiro que entrou', () {
      final line = _line(
        'Pix de Maria Souza',
        8000,
        kind: StatementLineKind.income,
        doubts: {LineDoubt.kind},
      );
      final question = StatementQuestion.of(0, line, ranked: const [])!;

      expect((question as KindQuestion).options.first, LineTreatment.income);
    });

    test('a de categoria oferece o palpite da IA e as mais usadas, quatro '
        'no máximo', () {
      final line = ResolvedLine(
        line: StatementLine(
          occurredOn: LocalDate(2026, 10, 12),
          description: 'Loja Estrela',
          amount: const Money.fromCents(15000),
        ),
        merchantKey: 'loja estrela',
        guess: 'home',
        doubts: const {LineDoubt.category},
      );
      final question = StatementQuestion.of(
        3,
        line,
        ranked: const ['groceries', 'home', 'bakery', 'health', 'transport'],
      )!;

      expect(question.line, 3);
      expect((question as CategoryQuestion).candidates, [
        'home',
        'groceries',
        'bakery',
        'health',
      ]);
    });

    test('linha certa não pergunta nada', () {
      expect(
        StatementQuestion.of(0, _line('Assaí', 100), ranked: const []),
        isNull,
      );
    });
  });
}
