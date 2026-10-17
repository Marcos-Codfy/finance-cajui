import 'dart:async';

import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Os lançamentos cancelados deslizando que ainda podem voltar (17/10/2026).
///
/// O cancelamento só é gravado quando a janela do Desfazer fecha: até lá a
/// linha só some da lista. Assim o Desfazer é de verdade — nada a refazer,
/// nada perdido de um lançamento dividido ou parcelado.
class PendingCancels extends Notifier<Set<String>> {
  final Map<String, Timer> _timers = {};

  /// Guardado na construção: na saída da tela o `ref` já não lê nada, e é
  /// justamente ali que o cancelamento pendente precisa ser gravado.
  late LedgerController _ledger;

  @override
  Set<String> build() {
    _ledger = ref.read(ledgerProvider.notifier);
    // Saiu da tela antes da janela fechar: o que foi cancelado, fica.
    ref.onDispose(() => [..._timers.keys].forEach(_write));
    return const {};
  }

  /// Tira [entryId] da lista e abre a janela do Desfazer.
  void hide(String entryId) {
    _timers[entryId]?.cancel();
    _timers[entryId] = Timer(CajuiDurations.undo, () {
      _write(entryId);
      state = {...state}..remove(entryId);
    });
    state = {...state, entryId};
  }

  /// Desfaz: a linha volta, e nada é gravado.
  void restore(String entryId) {
    _timers.remove(entryId)?.cancel();
    state = {...state}..remove(entryId);
  }

  void _write(String entryId) {
    _timers.remove(entryId)?.cancel();
    unawaited(
      _ledger.cancel(entryId, reason: 'Cancelado na lista de lançamentos'),
    );
  }
}

/// Os cancelamentos esperando a janela do Desfazer.
final NotifierProvider<PendingCancels, Set<String>> pendingCancelsProvider =
    NotifierProvider.autoDispose<PendingCancels, Set<String>>(
      PendingCancels.new,
    );
