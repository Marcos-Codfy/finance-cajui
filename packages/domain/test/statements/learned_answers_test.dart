import 'package:domain/domain.dart';
import 'package:test/test.dart';

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

void main() {
  group('RN-1116 · a resposta lembrada', () {
    test('a mais nova vence, venha na ordem que vier', () {
      final answers = LearnedAnswers.of([
        _answer('padaria boa vista', 10, category: 'bakery'),
        _answer('padaria boa vista', 9, category: 'groceries'),
      ]);

      expect(answers.forKey('padaria boa vista')!.categoryId, 'bakery');
    });

    test('esquecer tira a chave', () {
      final answers = LearnedAnswers.of([
        _answer('padaria boa vista', 9, category: 'bakery'),
        _answer('padaria boa vista', 10),
      ]);

      expect(answers.forKey('padaria boa vista'), isNull);
      expect(answers.length, 0);
    });

    test('a categoria dada depois de "É um gasto" leva o tipo junto', () {
      final first = _answer(
        'pessoa:joao p silva',
        9,
        treatment: LineTreatment.expense,
        person: true,
      );
      final then = _answer(
        'pessoa:joao p silva',
        10,
        category: 'home',
      ).merging(first);

      expect(then.treatment, LineTreatment.expense);
      expect(then.categoryId, 'home');
      expect(then.aboutPerson, isTrue);
    });
  });

  test('RN-1107 · resposta de pessoa nunca vira exemplo para a IA', () {
    final answers = LearnedAnswers.of([
      _answer('padaria boa vista', 9, category: 'bakery'),
      _answer('pessoa:joao p silva', 9, category: 'home', person: true),
      _answer('ifood', 9, treatment: LineTreatment.expense),
    ]);

    expect(answers.examples, {'padaria boa vista': 'bakery'});
  });
}
