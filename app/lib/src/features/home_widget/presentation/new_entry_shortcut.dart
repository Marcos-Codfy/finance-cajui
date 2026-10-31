import 'dart:async';

import 'package:cajui/src/core/navigation/coordinator_access.dart';
import 'package:cajui/src/features/ledger/presentation/ledger_coordinator.dart';
import 'package:flutter/widgets.dart';

/// O "+" do widget da tela inicial: abre o novo lançamento por cima do que
/// estiver na tela, o mesmo formulário do "Lançar" de dentro do app.
///
/// Abre por cima, e não depois de voltar ao Início como o número do widget:
/// quem toca no "+" quer lançar já, e ao fechar o formulário volta para
/// onde estava.
abstract final class NewEntryShortcut {
  /// O pedido que o lado nativo manda quando o "+" é tocado — o contrato
  /// com `MainActivity.NEW_ENTRY_ROUTE`.
  static const route = 'new-entry';

  /// Abre o novo lançamento, se [requested] é o pedido do "+". Devolve se
  /// o pedido era dele.
  static bool open(BuildContext context, String requested) {
    if (requested != route) return false;
    unawaited(context.coordinator(ledgerCoordinatorProvider).openEntryForm());
    return true;
  }
}
