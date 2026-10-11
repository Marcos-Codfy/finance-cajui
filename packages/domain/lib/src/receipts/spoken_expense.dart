import 'package:domain/src/ledger/possible_duplicate.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/money/money_format.dart';

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

  /// O primeiro valor dito em [text]: "40" é R$ 40,00, "8,50" é R$ 8,50, e
  /// "1.200" é mil e duzentos. `null` sem número.
  static Money? amountOf(String text) {
    final match = _amount.firstMatch(text);
    if (match == null) return null;
    final reais = match.group(1)!.replaceAll('.', '');
    final cents = (match.group(2) ?? '').padRight(2, '0');
    return Money.fromCents(int.parse(reais) * 100 + int.parse(cents));
  }

  /// [said] do jeito que o leitor de comprovante entende: a frase, e o valor
  /// com o rótulo de total (RN-753). Sem ele, "gastei 40" chegava à
  /// conferência sem valor, e o ditado não poupava nada.
  static String asReceipt(String said) {
    final amount = amountOf(said);
    return amount == null ? said : '$said\nTotal ${MoneyFormat.brl(amount)}';
  }

  /// Milhar com ponto e centavos com vírgula ou ponto: "1.200", "8,50",
  /// "8.50", "40".
  static final _amount = RegExp(
    r'(\d{1,3}(?:\.\d{3})+|\d+)(?:[,.](\d{1,2}))?(?!\d)',
  );
}
