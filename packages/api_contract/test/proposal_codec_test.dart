import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

const _groceries = Category(
  id: 'groceries',
  name: 'Mercado',
  block: Block.variable,
  groupId: 'food',
);

bool _knows(String id) => id == _groceries.id;

EntryProposal _proposal() => EntryProposal(
  documentKind: const ProposedField.resolved(
    DocumentKind.purchase,
    source: FieldSource.fixedRule,
  ),
  amount: const ProposedField.resolved(
    Money.fromCents(8600),
    source: FieldSource.fixedRule,
  ),
  occurredOn: ProposedField.resolved(
    LocalDate(2026, 9, 12),
    source: FieldSource.fixedRule,
  ),
  category: const ProposedField.undecided([
    'groceries',
  ], source: FieldSource.ai),
  paymentKind: const ProposedField.unread(),
  merchant: 'Mercado Boa Compra',
  description: 'Compra do mês',
  installments: 3,
  warnings: const ['E-AI-01'],
);

void main() {
  group('ProposalCodec', () {
    test('a proposta vai e volta inteira, com as zonas de confiança', () {
      final volta = ProposalCodec.decode(
        ProposalCodec.encode(_proposal()),
        knowsCategory: _knows,
      );

      expect(volta.amount.value, const Money.fromCents(8600));
      expect(volta.amount.confidence, Confidence.high);
      expect(volta.occurredOn.value, LocalDate(2026, 9, 12));
      expect(volta.documentKind.value, DocumentKind.purchase);
      expect(volta.category.value, isNull, reason: 'ficou em dúvida');
      expect(volta.category.candidates, ['groceries']);
      expect(volta.category.confidence, Confidence.medium);
      expect(volta.paymentKind.confidence, Confidence.low);
      expect(volta.merchant, 'Mercado Boa Compra');
      expect(volta.description, 'Compra do mês');
      expect(volta.installments, 3);
      expect(volta.warnings, ['E-AI-01']);
    });

    test('RN-742 · categoria que o aparelho não conhece cai fora, no valor '
        'e nos candidatos', () {
      final volta = ProposalCodec.decode(const {
        'categoryId': {
          'value': 'inventada',
          'candidates': ['inventada', 'groceries'],
          'confidence': 'high',
          'source': 'ai',
        },
      }, knowsCategory: _knows);

      expect(volta.category.value, isNull);
      expect(volta.category.candidates, ['groceries']);
    });

    test('campo fora do formato volta como não lido, e não derruba a '
        'proposta inteira (RN-747)', () {
      final volta = ProposalCodec.decode(const {
        'amountCents': 'não é um objeto',
        'occurredOn': {
          'value': '30/02/2026',
          'candidates': <Object?>[],
          'confidence': 'high',
          'source': 'fixedRule',
        },
        'merchant': 'Padaria',
      }, knowsCategory: _knows);

      expect(volta.amount.value, isNull);
      expect(volta.amount.confidence, Confidence.low);
      expect(volta.occurredOn.value, isNull, reason: 'fevereiro não tem 30');
      expect(volta.merchant, 'Padaria', reason: 'o resto sobreviveu');
    });

    test('resposta vazia vira uma proposta vazia, e não uma exceção', () {
      final volta = ProposalCodec.decode(const {}, knowsCategory: _knows);

      expect(volta.amount.value, isNull);
      expect(volta.warnings, isEmpty);
      expect(volta.installments, isNull);
    });

    test('origem desconhecida vira "nenhuma", em vez de estourar', () {
      final volta = ProposalCodec.decode(const {
        'merchant': 'X',
        'amountCents': {
          'value': 100,
          'candidates': <Object?>[],
          'confidence': 'high',
          'source': 'de-onde-vem-isso',
        },
      }, knowsCategory: _knows);

      expect(volta.amount.source, FieldSource.none);
      expect(volta.amount.value, const Money.fromCents(100));
    });
  });

  group('RN-707 · as linhas do extrato', () {
    test('vão e voltam inteiras', () {
      final extrato = EntryProposal(
        documentKind: const ProposedField.resolved(
          DocumentKind.statement,
          source: FieldSource.ai,
        ),
        amount: const ProposedField.unread(),
        occurredOn: const ProposedField.unread(),
        category: const ProposedField.unread(),
        paymentKind: const ProposedField.unread(),
        lines: [
          StatementLine(
            occurredOn: LocalDate(2026, 9, 3),
            description: 'Mercado Boa Compra',
            amount: const Money.fromCents(4590),
            categoryId: 'groceries',
            paymentKind: PaymentMethodKind.debit,
          ),
          StatementLine(
            occurredOn: LocalDate(2026, 9, 10),
            description: 'Fatura',
            amount: const Money.fromCents(150000),
            kind: StatementLineKind.cardPayment,
            doubtful: true,
          ),
        ],
      );

      final volta = ProposalCodec.decode(
        ProposalCodec.encode(extrato),
        knowsCategory: _knows,
      );

      expect(volta.isStatement, isTrue);
      expect(volta.lines.first.categoryId, 'groceries');
      expect(volta.lines.first.paymentKind, PaymentMethodKind.debit);
      expect(volta.lines.last.kind, StatementLineKind.cardPayment);
      expect(volta.lines.last.doubtful, isTrue);
      expect(volta.lines.first.doubtful, isFalse);
      expect(volta.lines.last.amount, const Money.fromCents(150000));
    });

    test('linha fora do formato cai sozinha; categoria desconhecida some '
        'da linha, que fica', () {
      Map<String, Object?> line(Object? cents, {String? categoryId}) => {
        'occurredOn': '2026-09-03',
        'description': 'Padaria',
        'amountCents': cents,
        'kind': 'expense',
        'categoryId': categoryId,
      };

      final volta = ProposalCodec.decode({
        'lines': [
          line(850, categoryId: 'inventada'),
          line(-100),
          line('muito'),
          'texto',
        ],
      }, knowsCategory: _knows);

      expect(volta.lines.single.amount, const Money.fromCents(850));
      expect(volta.lines.single.categoryId, isNull);
    });
  });
}
