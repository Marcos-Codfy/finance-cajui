import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:meta/meta.dart';

/// Os estados da tela de entrada da consulta. A tela faz `switch` exaustivo
/// sobre eles: estado novo sem desenho não compila (ADR-002).
@immutable
sealed class KeyState {
  const new();
}

/// A pessoa está digitando. Se a última tentativa não serviu, [problem] traz a
/// frase do catálogo.
final class KeyEditing extends KeyState {
  /// Cria o estado de digitação, com a recusa a resolver, se houver.
  const new({this.problem});

  /// Por que não entrou, com a frase do catálogo.
  final PresentedError? problem;
}

/// O código ou a chave está sendo conferido. O botão segura o segundo toque.
final class KeyEntering extends KeyState {
  /// Cria o estado de conferência.
  const new();
}

/// Entrou: a chave ficou guardada neste navegador e a casca já abre.
final class KeyEntered extends KeyState {
  /// Cria o estado final.
  const new();
}
