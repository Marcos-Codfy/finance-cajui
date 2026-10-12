import 'package:domain/src/ledger/possible_duplicate.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/money/money_format.dart';
import 'package:domain/src/receipts/spoken_amount.dart';

/// Reconhece a fala que **conta um gasto** — "gastei 40 no mercado no Pix" —
/// e não uma pergunta (RN-1091).
///
/// A Juju lança o que ouve quando há rede. Sem rede, ou com ela fora do ar,
/// a mesma frase ainda pode virar lançamento: o leitor do aparelho a lê como
/// leria um comprovante, e a conferência abre (BL-050). Esta regra decide
/// quando oferecer esse caminho — só para o que é gasto dito, nunca para
/// "quanto gastei em outubro?".
abstract final class SpokenExpense {
  /// Os verbos de quem conta que gastou, já sem acento.
  static const _verbs = {
    'gastei',
    'paguei',
    'comprei',
    'lanca',
    'lancar',
    'lance',
    'anota',
    'anotar',
  };

  /// O que faz da frase uma pergunta, já sem acento.
  static const _questions = {'quanto', 'quantos', 'qual', 'quais', 'onde'};

  static final _number = RegExp(r'\d');

  /// Se [text] conta um gasto: tem verbo de gasto, tem valor, e não é
  /// pergunta.
  static bool looksLikeExpense(String text) {
    if (text.trim().endsWith('?')) return false;
    final words = PossibleDuplicate.normalize(text).split(' ').toSet();
    if (words.any(_questions.contains)) return false;
    return words.any(_verbs.contains) && _number.hasMatch(text);
  }

  /// O valor dito em [text] (`SpokenAmount`): o número ao lado de "R$" ou
  /// de "reais", senão o primeiro que não seja dia, hora ou data. `null`
  /// quando não há valor seguro.
  static Money? amountOf(String text) => SpokenAmount.of(text);

  /// [said] do jeito que o leitor de comprovante entende: a frase, e o valor
  /// com o rótulo de total (RN-753). Sem ele, "gastei 40" chegava à
  /// conferência sem valor, e o ditado não poupava nada.
  static String asReceipt(String said) {
    final amount = amountOf(said);
    return amount == null ? said : '$said\nTotal ${MoneyFormat.brl(amount)}';
  }
}
