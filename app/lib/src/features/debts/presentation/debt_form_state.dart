import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:meta/meta.dart';

/// Os estados da tela de cadastro de dívida. A tela faz `switch` exaustivo
/// sobre eles: estado novo sem desenho não compila (ADR-002).
@immutable
sealed class DebtFormState {
  const new();
}

/// A pessoa está preenchendo. Se uma regra recusou a última tentativa,
/// [problem] diz qual, e fica na tela até ser dispensado (RNF-A11Y-13).
final class DebtFormEditing extends DebtFormState {
  /// Cria o estado de edição, com a recusa a resolver, se houver.
  const new({this.problem});

  /// A recusa a resolver, com a frase do catálogo.
  final PresentedError? problem;
}

/// A dívida está sendo gravada. O botão segura o segundo toque.
final class DebtFormSaving extends DebtFormState {
  /// Cria o estado de gravação.
  const new();
}

/// Gravada. A tela fecha e a lista já mostra a dívida.
final class DebtFormSaved extends DebtFormState {
  /// Cria o estado final.
  const new();
}
