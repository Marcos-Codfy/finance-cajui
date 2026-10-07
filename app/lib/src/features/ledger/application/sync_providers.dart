import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_downlink.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/ledger/application/ledger_pull.dart';
import 'package:cajui/src/features/ledger/application/ledger_sync.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A sincronização inteira — subir e descer — para quem a pede pela tela:
/// a pergunta ao assistente. A que acontece sozinha
/// depois de cada lançamento vive no controlador do livro.
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
