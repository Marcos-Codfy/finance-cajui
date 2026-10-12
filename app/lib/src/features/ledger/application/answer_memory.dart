import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Os casos de uso da memória das respostas (RN-1116): lembrar e esquecer.
///
/// A resposta é lembrada na hora em que é dada, e não no fim da conversa:
/// fechar o app no meio de um extrato não perde o que já foi respondido
/// (RN-1115). Grava pelo mesmo caminho do livro, um fato de cada vez, e
/// sobe para o outro celular como os nomes da casa.
class AnswerMemory {
  /// Cria o caso de uso sobre os providers de [ref].
  const new(this.ref);

  /// De onde saem o livro, o relógio e o gerador de identificador.
  final Ref ref;

  LedgerController get _ledger => ref.read(ledgerProvider.notifier);

  /// Lembra a resposta para [key]: a categoria [categoryId], o tipo
  /// [treatment], ou os dois. [aboutPerson] diz que a chave é o nome de
  /// alguém: a resposta vale no celular e nunca vira exemplo para a IA
  /// (RN-1107).
  ///
  /// O que esta resposta não diz vem da que já estava lembrada: a categoria
  /// dada depois de "É um gasto" não apaga o tipo. Devolve se gravou —
  /// resposta igual à lembrada, sem nada a dizer, ou de chave que não cabe
  /// num fato, não grava.
  Future<bool> remember({
    required String key,
    String? categoryId,
    LineTreatment? treatment,
    bool aboutPerson = false,
  }) async {
    if (!LearnedAnswerCodec.fits(key)) return false;
    if (categoryId == null && treatment == null) return false;
    final recorded = await _ledger.appendFrom((book) {
      final known = book.learnedAnswers.forKey(key);
      final answer = LearnedAnswer(
        key: key,
        definedAt: _stamp(known),
        categoryId: categoryId,
        treatment: treatment,
        aboutPerson: aboutPerson,
      ).merging(known);
      return _same(answer, known) ? null : _fact(answer);
    });
    return recorded != null;
  }

  /// Esquece a resposta para [key]: o lugar volta a ser perguntado, nos dois
  /// celulares. Devolve se havia o que esquecer.
  Future<bool> forget(String key) async {
    final recorded = await _ledger.appendFrom((book) {
      final known = book.learnedAnswers.forKey(key);
      if (known == null) return null;
      return _fact(
        LearnedAnswer(
          key: key,
          definedAt: _stamp(known),
          aboutPerson: known.aboutPerson,
        ),
      );
    });
    return recorded != null;
  }

  AnswerLearned _fact(LearnedAnswer answer) =>
      AnswerLearned(id: 'answer-${ref.read(newIdProvider)()}', answer: answer);

  /// Agora — e nunca antes da resposta que este celular já tem. Quem
  /// responde depois de ver a resposta do outro celular está respondendo a
  /// ela, e a sua tem de valer, mesmo com o relógio daqui atrasado.
  DateTime _stamp(LearnedAnswer? known) {
    final now = ref.read(clockProvider).now();
    final before = known?.definedAt;
    if (before == null || now.isAfter(before)) return now;
    return before.add(const Duration(milliseconds: 1));
  }

  static bool _same(LearnedAnswer answer, LearnedAnswer? known) =>
      known != null &&
      known.categoryId == answer.categoryId &&
      known.treatment == answer.treatment &&
      known.aboutPerson == answer.aboutPerson;
}

/// Os casos de uso da memória das respostas.
final answerMemoryProvider = Provider<AnswerMemory>(AnswerMemory.new);
