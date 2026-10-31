import 'package:cajui/src/core/navigation/navigation_providers.dart';
import 'package:cajui/src/core/navigation/scene_navigator.dart';
import 'package:cajui/src/features/review/presentation/review_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Para onde leva a revisão da semana (ADR-031).
final class ReviewCoordinator {
  /// Cria o coordinator sobre o navegador de cenas.
  const new(this._navigator);

  final SceneNavigator _navigator;

  /// A revisão da semana.
  Future<void> openReview() => _navigator.push<void>(const ReviewPage());
}

/// O coordinator da revisão.
final reviewCoordinatorProvider = Provider<ReviewCoordinator>(
  (ref) => ReviewCoordinator(ref.watch(sceneNavigatorProvider)),
);
