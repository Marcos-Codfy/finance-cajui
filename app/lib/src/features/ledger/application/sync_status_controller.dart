import 'package:cajui/src/features/ledger/application/sync_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Quem anota o estado da sincronização; quem escreve é a sincronização
/// silenciosa (`QuietSync`), a cada rodada.
class SyncStatusController extends Notifier<SyncStatus> {
  @override
  SyncStatus build() => const SyncStatus();

  /// Começou uma rodada.
  void started() => state = SyncStatus(
    running: true,
    lastOkAt: state.lastOkAt,
    failing: state.failing,
  );

  /// A rodada terminou em [at]; [ok] quando subiu e desceu sem erro.
  void finished({required bool ok, required DateTime at}) => state = ok
      ? SyncStatus(lastOkAt: at)
      : SyncStatus(lastOkAt: state.lastOkAt, failing: true);
}

/// O estado da sincronização.
final syncStatusProvider = NotifierProvider<SyncStatusController, SyncStatus>(
  SyncStatusController.new,
);
