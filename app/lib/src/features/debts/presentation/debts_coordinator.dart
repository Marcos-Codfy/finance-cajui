import 'package:cajui/src/core/navigation/navigation_providers.dart';
import 'package:cajui/src/core/navigation/scene_navigator.dart';
import 'package:cajui/src/features/debts/presentation/debt_detail_page.dart';
import 'package:cajui/src/features/debts/presentation/debt_form_page.dart';
import 'package:cajui/src/features/debts/presentation/debts_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Para onde levam as telas das dívidas (ADR-031).
final class DebtsCoordinator {
  /// Cria o coordinator sobre o navegador de cenas.
  const new(this._navigator);

  final SceneNavigator _navigator;

  /// A lista de dívidas.
  Future<void> openDebts() => _navigator.push<void>(const DebtsPage());

  /// O detalhe da dívida [debtId].
  Future<void> openDebt(String debtId) =>
      _navigator.push<void>(DebtDetailPage(debtId: debtId));

  /// O cadastro de uma dívida nova.
  Future<void> openDebtForm() => _navigator.push<void>(const DebtFormPage());

  /// Fecha a tela atual.
  void close() => _navigator.pop();
}

/// O coordinator das dívidas.
final debtsCoordinatorProvider = Provider<DebtsCoordinator>(
  (ref) => DebtsCoordinator(ref.watch(sceneNavigatorProvider)),
);
