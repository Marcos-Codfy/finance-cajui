import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_downlink.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/ledger/application/ledger_pull.dart';
import 'package:cajui/src/features/ledger/application/ledger_sync.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A sincronização inteira — subir e descer —, com o resultado na mão:
/// quantos subiram, quantos desceram e a primeira recusa. O app não a chama
/// por aqui: tudo passa pela fila da `QuietSync`, no controlador do livro,
/// para nunca haver duas ao mesmo tempo (ADR-024). Fica para quem precisa
/// do resultado — o teste de dois celulares.
final ledgerSyncProvider = Provider<LedgerSync>(
  (ref) => LedgerSync(
    ref.watch(ledgerUplinkProvider),
    pull: LedgerPull(
      ref.watch(ledgerDownlinkProvider),
      clock: ref.watch(clockProvider),
      absorb: ref.read(ledgerProvider.notifier).absorb,
    ),
  ),
);
