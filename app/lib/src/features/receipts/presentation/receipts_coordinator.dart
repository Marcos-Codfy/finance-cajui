import 'package:cajui/src/core/navigation/navigation_providers.dart';
import 'package:cajui/src/core/navigation/scene_navigator.dart';
import 'package:cajui/src/features/receipts/presentation/read_text_page.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Para onde levam as telas da captura de comprovante (ADR-031).
final class ReceiptsCoordinator {
  /// Cria o coordinator sobre o navegador de cenas.
  const new(this._navigator);

  final SceneNavigator _navigator;

  /// O texto cru que foi lido do comprovante, com a [proposal] que saiu dele.
  Future<void> openReadText(String text, {EntryProposal? proposal}) =>
      _navigator.push<void>(ReadTextPage(text: text, proposal: proposal));
}

/// O coordinator da captura.
final receiptsCoordinatorProvider = Provider<ReceiptsCoordinator>(
  (ref) => ReceiptsCoordinator(ref.watch(sceneNavigatorProvider)),
);
