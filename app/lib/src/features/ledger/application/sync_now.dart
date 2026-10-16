import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sincronizar agora: no celular, sobe o que falta e desce o que mudou; na
/// web, que só consulta, relê o que o servidor tem. É o mesmo caminho da
/// conferência automática — a cada gravação, a cada 20 s e na volta ao app
/// — e do puxar para atualizar do Início (16/10/2026). Devolve se deu.
final syncNowProvider = Provider<Future<bool> Function()>(
  (ref) => () async {
    // Na abertura o livro ainda está abrindo: esperar por ele é o que faz a
    // subida acontecer também na primeira vez do dia.
    final book = await ref.read(ledgerProvider.future);
    final ledger = ref.read(ledgerProvider.notifier);
    if (!ref.read(ledgerUplinkProvider).isPaired) return await ledger.reload();
    return await ledger.quietSync.request(book);
  },
);
