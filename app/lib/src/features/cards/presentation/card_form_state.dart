import 'package:meta/meta.dart';

/// Os estados da tela de cadastro de cartão. A tela faz `switch` exaustivo
/// sobre eles: estado novo sem desenho não compila (ADR-002).
@immutable
sealed class CardFormState {
  const new();
}

/// A pessoa está preenchendo. Se uma regra recusou a última tentativa,
/// [dayProblem] traz a frase do catálogo, que a tela mostra no campo dos dias.
final class CardFormEditing extends CardFormState {
  /// Cria o estado de edição, com a recusa a resolver, se houver.
  const new({this.dayProblem});

  /// A frase do catálogo para o dia recusado, ou `null`.
  final String? dayProblem;
}

/// O cartão está sendo gravado. O botão segura o segundo toque.
final class CardFormSaving extends CardFormState {
  /// Cria o estado de gravação.
  const new();
}

/// Gravado. A tela fecha e a carteira já mostra o cartão.
final class CardFormSaved extends CardFormState {
  /// Cria o estado final.
  const new();
}
