import 'package:cajui/src/core/navigation/navigation_providers.dart';
import 'package:cajui/src/core/navigation/scene_navigator.dart';
import 'package:cajui/src/features/cards/presentation/card_form_page.dart';
import 'package:cajui/src/features/cards/presentation/cards_page.dart';
import 'package:cajui/src/features/cards/presentation/statement_page.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Para onde levam as telas dos cartões de crédito (ADR-031).
final class CardsCoordinator {
  /// Cria o coordinator sobre o navegador de cenas.
  const new(this._navigator);

  final SceneNavigator _navigator;

  /// A carteira de cartões.
  Future<void> openCards() => _navigator.push<void>(const CardsPage());

  /// O cadastro de um cartão; com [card], para alterá-lo.
  Future<void> openCardForm({CreditCard? card}) =>
      _navigator.push<void>(CardFormPage(card: card));

  /// A fatura de [card].
  Future<void> openStatement(CreditCard card) =>
      _navigator.push<void>(StatementPage(card: card));

  /// Fecha a tela atual.
  void close() => _navigator.pop();
}

/// O coordinator dos cartões.
final cardsCoordinatorProvider = Provider<CardsCoordinator>(
  (ref) => CardsCoordinator(ref.watch(sceneNavigatorProvider)),
);
