import 'package:domain/src/shared/edit_stamp.dart';
import 'package:domain/src/statements/learned_answer.dart';

/// Todas as respostas lembradas, uma por chave: a mais nova vence
/// (RN-1116), venha de que celular vier.
final class LearnedAnswers {
  /// Junta [answers], na ordem que for: a mais nova de cada chave fica, e
  /// a esquecida tira a chave.
  factory of(Iterable<LearnedAnswer> answers) {
    final newest = <String, LearnedAnswer>{};
    for (final answer in answers) {
      final known = newest[answer.key];
      if (known == null ||
          EditStamp.isNewer(answer.definedAt, known.definedAt)) {
        newest[answer.key] = answer;
      }
    }
    newest.removeWhere((_, answer) => answer.isForgotten);
    return LearnedAnswers._(newest);
  }

  const new _(this._byKey);

  /// Nenhuma resposta ainda.
  static const empty = LearnedAnswers._({});

  final Map<String, LearnedAnswer> _byKey;

  /// A resposta lembrada para [key], ou `null`.
  LearnedAnswer? forKey(String key) => _byKey[key];

  /// Quantas há.
  int get length => _byKey.length;

  /// As que podem ir à IA como exemplo, chave → categoria: nunca as de
  /// pessoa (RN-1107), e só as que dizem a categoria.
  Map<String, String> get examples => {
    for (final answer in _byKey.values)
      if (!answer.aboutPerson && answer.categoryId != null)
        answer.key: answer.categoryId!,
  };
}
