import 'package:domain/src/statements/learned_answer.dart';
import 'package:domain/src/statements/learned_answers.dart';
import 'package:domain/src/statements/merchant_brand.dart';
import 'package:domain/src/statements/transfer_line.dart';

/// As regras de categoria que a classificação do celular usa: a memória das
/// respostas, que atravessa os celulares (RN-1116), por cima das regras
/// antigas do comprovante, que ficaram só no aparelho onde foram ensinadas
/// (RN-763).
///
/// Separa as regras em duas: as que podem ir à IA como exemplo e as que
/// falam de pessoa, que valem só no celular (RN-1107). A regra antiga não
/// guardava se era de pessoa; ela é julgada pelo nome.
final class LearnedRules {
  /// Junta [answers], todas as respostas na ordem em que chegaram, às
  /// regras antigas [legacy] (estabelecimento normalizado → categoria).
  ///
  /// A chave de que a memória já ouviu falar é decidida por ela: a resposta
  /// em vigor vale por cima da regra antiga — e, se não diz a categoria, a
  /// da regra antiga continua —, e a esquecida leva a regra antiga junto.
  factory of({
    Iterable<LearnedAnswer> answers = const [],
    Map<String, String> legacy = const {},
  }) {
    final memory = LearnedAnswers.of(answers);
    final told = {for (final answer in answers) answer.key};
    final rules = LearnedRules._({}, {});
    for (final MapEntry(:key, :value) in legacy.entries) {
      if (!told.contains(key)) rules._put(key, value, person: false);
    }
    // As mais novas por último: é do fim que saem os exemplos quando são
    // muitos (RN-769).
    final live = [for (final key in told) ?memory.forKey(key)]
      ..sort((a, b) => a.definedAt.compareTo(b.definedAt));
    for (final answer in live) {
      final category = answer.categoryId ?? legacy[answer.key];
      if (category == null) continue;
      rules._put(answer.key, category, person: answer.aboutPerson);
    }
    return rules;
  }

  new _(this._shared, this._personal);

  final Map<String, String> _shared;
  final Map<String, String> _personal;

  /// As que podem ir à IA como exemplo, chave → categoria.
  Map<String, String> get shared => Map.unmodifiable(_shared);

  /// As que falam de pessoa: valem nas regras do celular e nunca saem dele.
  Map<String, String> get personal => Map.unmodifiable(_personal);

  /// Põe a regra no lado certo. Na dúvida, vai para o lado de pessoa: o
  /// pior que acontece é a IA ter um exemplo a menos.
  void _put(String key, String category, {required bool person}) {
    final private = person || looksLikePerson(key);
    (private ? _personal : _shared)[key] = category;
  }

  /// Se [key] fala de uma pessoa: a chave de Pix com pessoa da memória
  /// (`StatementLineResolver.personKey`, que começa com "pessoa:") ou um
  /// nome com cara de gente que não é marca conhecida (RN-1107).
  static bool looksLikePerson(String key) =>
      key.startsWith(_personPrefix) ||
      (MerchantBrand.of(key) == null && TransferLine.isPersonName(key));

  /// O começo da chave que `StatementLineResolver.personKey` monta. Chave de
  /// estabelecimento nunca tem dois-pontos: a normalização (RN-727) os tira.
  static const _personPrefix = 'pessoa:';
}
