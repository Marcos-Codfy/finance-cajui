import 'package:domain/domain.dart';
import 'package:test/test.dart';

StatementLine _raw(
  String description, {
  StatementLineKind kind = StatementLineKind.expense,
  String? category,
  Confidence confidence = Confidence.medium,
  bool doubtful = false,
}) => StatementLine(
  occurredOn: LocalDate(2026, 10, 12),
  description: description,
  amount: const Money.fromCents(15000),
  kind: kind,
  categoryId: category,
  confidence: confidence,
  doubtful: doubtful,
);

String? _catalog(MerchantKind kind) => switch (kind) {
  MerchantKind.delivery => 'eating-out',
  MerchantKind.rideHailing => 'transport',
  MerchantKind.streaming => 'subscriptions',
  _ => null,
};

LearnedAnswers _remember(LearnedAnswer answer) => LearnedAnswers.of([answer]);

void main() {
  group('RN-1109 · a precedência da categoria', () {
    test('a resposta lembrada vence a IA', () {
      final line = StatementLineResolver.resolve(
        _raw(
          'Padaria Boa Vista',
          category: 'groceries',
          confidence: Confidence.high,
        ),
        memory: _remember(
          LearnedAnswer(
            key: 'padaria boa vista',
            categoryId: 'bakery',
            definedAt: DateTime.utc(2026, 10),
          ),
        ),
      );

      expect(line.line.categoryId, 'bakery');
      expect(line.isSure, isTrue);
    });

    test('a marca conhecida vence a IA, e o nome é o da marca', () {
      final line = StatementLineResolver.resolve(
        _raw('Restaurante Sabor', category: 'groceries'),
        original: 'IFD*RESTAURANTE SABOR 12/10 150,00',
        categoryOfKind: _catalog,
      );

      expect(line.line.description, 'iFood');
      expect(line.line.categoryId, 'eating-out');
      expect(line.merchantKey, 'ifood');
      expect(line.isSure, isTrue);
    });

    test('a IA decide sozinha só com confiança alta', () {
      final sure = StatementLineResolver.resolve(
        _raw(
          'Farmácia Central',
          category: 'health',
          confidence: Confidence.high,
        ),
      );
      final unsure = StatementLineResolver.resolve(
        _raw('Loja Estrela', category: 'home'),
      );

      expect(sure.line.categoryId, 'health');
      expect(sure.isSure, isTrue);
      expect(unsure.line.categoryId, isNull);
      expect(unsure.doubts, {LineDoubt.category});
      expect(unsure.guess, 'home', reason: 'a pergunta oferece primeiro');
    });
  });

  group('RN-1110 · o tipo de cada linha', () {
    test('Pix para alguém que ninguém ensinou é pergunta, com o nome só no '
        'celular', () {
      final line = StatementLineResolver.resolve(
        _raw('Pix para [NOME]'),
        original: 'PIX ENVIADO JOAO P SILVA 150,00',
      );

      expect(line.doubts, contains(LineDoubt.kind));
      expect(line.person, 'JOAO P SILVA');
      expect(line.line.description, startsWith('Pix para'));
      expect(line.merchantKey, 'pessoa:joao p silva');
    });

    test('Pix para alguém da casa não é gasto, e não pergunta', () {
      final line = StatementLineResolver.resolve(
        _raw('Pix para [NOME]'),
        original: 'PIX ENVIADO BEATRIZ M LIMA 150,00',
        household: HouseholdNames(
          names: const ['Beatriz Muniz Lima'],
          definedAt: DateTime.utc(2026, 10),
        ),
      );

      expect(line.treatment, LineTreatment.household);
      expect(line.isLeftOut, isTrue);
      expect(line.isSure, isTrue);
    });

    test('"conta minha" lembrada: fica fora da conta, sem perguntar', () {
      final line = StatementLineResolver.resolve(
        _raw('Pix para [NOME]'),
        original: 'PIX ENVIADO MARCOS V M ARRUDA 500,00',
        memory: _remember(
          LearnedAnswer(
            key: 'pessoa:marcos v m arruda',
            treatment: LineTreatment.ownAccount,
            aboutPerson: true,
            definedAt: DateTime.utc(2026, 10),
          ),
        ),
      );

      expect(line.treatment, LineTreatment.ownAccount);
      expect(line.isLeftOut, isTrue);
      expect(line.isSure, isTrue);
    });

    test('pagamento de fatura escrito na linha: fora da conta, sem '
        'categoria a perguntar (RN-756)', () {
      final line = StatementLineResolver.resolve(
        _raw('Pagamento de fatura', kind: StatementLineKind.cardPayment),
      );

      expect(line.isLeftOut, isTrue);
      expect(line.isSure, isTrue);
    });

    test('o tipo que só a IA disse vira pergunta', () {
      final line = StatementLineResolver.resolve(
        _raw(
          'Transferência',
          kind: StatementLineKind.ownTransfer,
          doubtful: true,
        ),
      );

      expect(line.doubts, contains(LineDoubt.kind));
    });

    test(
      'Pix recebido de alguém de fora pergunta se é dinheiro que entrou',
      () {
        final line = StatementLineResolver.resolve(
          _raw('Pix de [NOME]', kind: StatementLineKind.income),
          original: 'PIX RECEBIDO DE MARIA SOUZA 80,00',
        );

        expect(line.doubts, {LineDoubt.kind});
        expect(line.line.description, startsWith('Pix de'));
      },
    );
  });
}
