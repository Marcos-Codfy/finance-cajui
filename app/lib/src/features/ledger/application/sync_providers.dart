import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_downlink.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/ledger/application/ledger_pull.dart';
import 'package:cajui/src/features/ledger/application/ledger_sync.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Se o livro sobe sozinho agora, sem pedir nada a quem usa. Falso quando a
/// chave do dia ainda não foi liberada, quando não há rede, ou quando o
/// servidor não conhece este aparelho: em todos o que for lançado fica só
/// aqui, e o painel diz isso (BL-061) — com a saída de cada caso. Quem
/// envia, pergunta ao assistente ou volta ao app manda conferir de novo.
final quietSendProvider = FutureProvider<bool>(
  (ref) => ref.watch(ledgerUplinkProvider).canSendQuietly(),
);

/// A sincronização inteira — subir e descer — para quem a pede pela tela:
/// o botão em Ajustes e a pergunta ao assistente. A que acontece sozinha
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
