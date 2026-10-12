import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

LearnedAnswer _answer(
  String key,
  int hour, {
  String? category,
  LineTreatment? treatment,
  bool person = false,
}) => LearnedAnswer(
  key: key,
  definedAt: DateTime.utc(2026, 10, 11, hour),
  categoryId: category,
  treatment: treatment,
  aboutPerson: person,
);

/// Um Pix para uma pessoa, com o nome no rótulo de quem recebeu.
const _pixToPerson = r'''
Comprovante de Pix
Valor: R$ 150,00
Destinatário: João P. Silva
10/09/2026''';

void main() {
  group('RN-1116 · a memória por cima das regras antigas', () {
    test('a resposta lembrada vence a regra antiga da mesma chave', () {
      final rules = LearnedRules.of(
        answers: [_answer('padaria boa vista', 9, category: 'bakery')],
        legacy: const {'padaria boa vista': 'groceries'},
      );

      expect(rules.shared, {'padaria boa vista': 'bakery'});
    });

    test('a regra antiga que a memória não conhece continua valendo', () {
      final rules = LearnedRules.of(
        answers: [_answer('padaria boa vista', 9, category: 'bakery')],
        legacy: const {'posto central': 'fuel'},
      );

      expect(rules.shared, {
        'posto central': 'fuel',
        'padaria boa vista': 'bakery',
      });
    });

    test('esquecer leva a regra antiga junto', () {
      final rules = LearnedRules.of(
        answers: [
          _answer('padaria boa vista', 9, category: 'bakery'),
          _answer('padaria boa vista', 10),
        ],
        legacy: const {'padaria boa vista': 'groceries'},
      );

      expect(rules.shared, isEmpty);
      expect(rules.personal, isEmpty);
    });

    test('resposta só de tipo não apaga a categoria da regra antiga', () {
      final rules = LearnedRules.of(
        answers: [
          _answer('padaria boa vista', 9, treatment: LineTreatment.expense),
        ],
        legacy: const {'padaria boa vista': 'bakery'},
      );

      expect(rules.shared, {'padaria boa vista': 'bakery'});
    });

    test('as respostas mais novas ficam no fim, de onde saem os exemplos', () {
      final rules = LearnedRules.of(
        answers: [
          _answer('posto central', 11, category: 'fuel'),
          _answer('padaria boa vista', 9, category: 'bakery'),
        ],
      );

      expect(rules.shared.keys, ['padaria boa vista', 'posto central']);
    });
  });

  group('RN-1107 · resposta de pessoa nunca vira exemplo para a IA', () {
    test('a resposta lembrada de pessoa fica só no celular', () {
      final key = StatementLineResolver.personKey('João P Silva');
      final rules = LearnedRules.of(
        answers: [_answer(key, 9, category: 'services', person: true)],
      );

      expect(rules.shared, isEmpty);
      expect(rules.personal, {key: 'services'});
    });

    test('a regra antiga com cara de nome de gente também fica', () {
      final rules = LearnedRules.of(
        legacy: const {
          'joao p silva': 'services',
          'padaria boa vista': 'bakery',
          'uber eats': 'eating-out',
        },
      );

      expect(rules.shared, {
        'padaria boa vista': 'bakery',
        'uber eats': 'eating-out',
      });
      expect(rules.personal, {'joao p silva': 'services'});
    });

    test('resposta sem a marca de pessoa, mas com nome de gente, também '
        'fica', () {
      final rules = LearnedRules.of(
        answers: [_answer('maria souza', 9, category: 'services')],
      );

      expect(rules.shared, isEmpty);
    });

    test('a chave de pessoa da memória é reconhecida pelo começo', () {
      expect(
        LearnedRules.looksLikePerson(
          StatementLineResolver.personKey('Ana Lima'),
        ),
        isTrue,
      );
      expect(LearnedRules.looksLikePerson('padaria central'), isFalse);
      expect(LearnedRules.looksLikePerson('netflix'), isFalse);
    });

    test('a regra de pessoa continua valendo nas regras do celular', () async {
      final proposal = await const RuleBasedClassifier().classify(
        ClassificationRequest(
          text: ReceiptText.clean(_pixToPerson),
          categories: const [groceries, leisure],
          today: today,
          personalRules: const {'joao p silva': 'leisure'},
        ),
      );

      expect(proposal.category.value, 'leisure');
      expect(proposal.category.source, FieldSource.learnedRule);
    });

    test('e vai junto quando o pedido perde a imagem', () {
      final request = ClassificationRequest(
        text: 'x',
        categories: const [groceries],
        today: today,
        personalRules: const {'joao p silva': 'groceries'},
      );

      expect(request.withoutImages().personalRules, {
        'joao p silva': 'groceries',
      });
    });
  });

  group('RN-1106 · nome de gente sem a linha em volta', () {
    test('nome e sobrenome é gente; ramo, empresa e uma palavra só, não', () {
      expect(TransferLine.isPersonName('joao p silva'), isTrue);
      expect(TransferLine.isPersonName('padaria boa vista'), isFalse);
      expect(TransferLine.isPersonName('lojas centro'), isFalse);
      expect(TransferLine.isPersonName('drogasil'), isFalse);
    });
  });
}
