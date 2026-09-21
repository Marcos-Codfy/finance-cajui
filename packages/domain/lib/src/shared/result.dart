import 'package:domain/src/shared/failure.dart';

/// O resultado de uma operação que pode ser recusada por uma regra.
///
/// Regra de negócio recusada **não é exceção**: é um valor de retorno, e o
/// compilador obriga quem chama a olhar para os dois casos. É assim que o
/// erro genérico deixa de ser possível (ADR-015).
sealed class Result<T> {
  const new();

  /// A operação deu certo.
  bool get isOk => this is Ok<T>;

  /// O valor, se deu certo; nulo, se foi recusada.
  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  /// A falha, se foi recusada; nulo, se deu certo.
  Failure? get failureOrNull => switch (this) {
    Ok() => null,
    Err(:final failure) => failure,
  };
}

/// Deu certo, e este é o valor.
final class Ok<T> extends Result<T> {
  /// Cria o resultado de sucesso com [value].
  const new(this.value);

  /// O valor produzido.
  final T value;
}

/// Foi recusada, e esta é a falha.
final class Err<T> extends Result<T> {
  /// Cria o resultado de recusa com [failure].
  const new(this.failure);

  /// A regra que recusou, com os dados que o texto do erro usa.
  final Failure failure;
}
