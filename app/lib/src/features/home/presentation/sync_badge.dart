import 'dart:async';

import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/ledger/application/sync_now.dart';
import 'package:cajui/src/features/ledger/application/sync_status.dart';
import 'package:cajui/src/features/ledger/application/sync_status_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A linha discreta do alto do Início que diz se o servidor tem tudo
/// (17/10/2026): sincronizado, sincronizando ou sem conexão. Um toque
/// sincroniza na hora, como o puxar para atualizar.
class SyncBadge extends ConsumerWidget {
  /// Cria o selo.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    final words = wordsOf(status, now: ref.read(clockProvider).now());
    if (words == null) return const SizedBox.shrink();
    return CajuiPressable(
      onPressed: () => unawaited(ref.read(syncNowProvider)()),
      semanticLabel: '$words. Toque para sincronizar agora',
      builder: (context, _) => _line(context, words, failing: status.failing),
    );
  }

  static Widget _line(
    BuildContext context,
    String words, {
    required bool failing,
  }) {
    final theme = CajuiTheme.of(context);
    final faint = theme.colors.text.faint;
    return Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.md),
      child: Row(
        spacing: CajuiSpacing.xs,
        children: [
          CajuiIcon(
            failing ? CajuiIconData.offline : CajuiIconData.check,
            size: 16,
            color: faint,
          ),
          Flexible(
            child: Text(
              words,
              style: theme.typography.caption.copyWith(color: faint),
            ),
          ),
        ],
      ),
    );
  }

  /// A frase do selo em [now]; nula antes da primeira conversa.
  ///
  /// Sem conexão, diz também de quando é o que está na tela: o número do
  /// Painel pode ser de ontem, e quem o lê precisa saber (27/11/2026).
  static String? wordsOf(SyncStatus status, {required DateTime now}) {
    if (status.running) return 'Sincronizando…';
    final at = status.lastOkAt;
    if (status.failing) {
      final since = at == null
          ? ''
          : ' · atualizado ${DateLabels.when(at, now: now)}';
      return 'Sem conexão com o servidor$since · o que você lançar sobe '
          'depois';
    }
    if (at == null) return null;
    return now.difference(at).inMinutes < 1
        ? 'Sincronizado agora'
        : 'Sincronizado ${DateLabels.when(at, now: now)}';
  }
}
