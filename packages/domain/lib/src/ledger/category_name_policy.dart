import 'package:domain/src/ledger/possible_duplicate.dart';
import 'package:domain/src/shared/failure.dart';

/// Impede que o cartão de crédito volte pela porta dos fundos, disfarçado de
/// categoria (RN-207 e RN-301).
///
/// "Cartão" e "Fatura" como categoria recriariam o erro que o Cajui existe
/// para evitar: a fatura virar uma despesa opaca, que esconde o que foi
/// comprado. A categoria diz **o que**; o cartão entra em **por onde**.
abstract final class CategoryNamePolicy {
  /// Palavras que denunciam um cartão ou uma fatura. "Crédito" fica de fora
  /// de propósito: "crédito de celular" é uma despesa legítima.
  static const _cardWords = {'cartao', 'cartoes', 'fatura', 'faturas'};

  /// A falha de [name], se ele representar cartão ou fatura; senão, nulo.
  static Failure? check(String name) {
    final words = PossibleDuplicate.normalize(name).split(' ');
    return words.any(_cardWords.contains) ? CategoryRepresentsCard(name) : null;
  }
}
