import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// Os estados da revisão da semana. A tela faz `switch` exaustivo sobre
/// eles (ADR-002).
@immutable
sealed class ReviewState {
  const new();
}

/// O livro ainda está abrindo.
final class ReviewLoading extends ReviewState {
  /// Cria o estado.
  const new();
}

/// Nada ficou para conferir.
final class ReviewClear extends ReviewState {
  /// Cria o estado.
  const new();
}

/// Há gastos esperando um olhar (RN-870).
final class ReviewPending extends ReviewState {
  /// Cria o estado com [items], que se corrigem para uma de [categories].
  const new({required this.items, required this.categories, this.error});

  /// Os gastos, os mais recentes primeiro.
  final List<Entry> items;

  /// As categorias que se oferecem em um toque.
  final List<Category> categories;

  /// A correção que a regra recusou, quando houve.
  final PresentedError? error;
}
