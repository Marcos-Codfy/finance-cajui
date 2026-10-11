import 'dart:async';

import 'package:cajui/src/features/reminders/application/reminders_providers.dart';
import 'package:cajui/src/features/reminders/application/reminders_switch.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A linha de Ajustes dos lembretes de vencimento (RN-1088): a chave, o que
/// ela faz e, se o Android segura as notificações do Cajui, como liberar.
///
/// A permissão de notificar é do sistema e pode mudar fora do app; por isso
/// a linha confere de novo toda vez que o app volta à frente.
class DueRemindersRow extends ConsumerStatefulWidget {
  /// Cria a linha.
  const new({super.key});

  /// O nome da chave, o mesmo da regra.
  static const title = 'Lembrar das contas a vencer';

  @override
  ConsumerState<DueRemindersRow> createState() => _DueRemindersRowState();
}

class _DueRemindersRowState extends ConsumerState<DueRemindersRow>
    with WidgetsBindingObserver {
  bool _canPost = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// A pessoa volta da pergunta do sistema, ou da tela de notificações do
  /// Android: é na volta que a linha descobre se ficou liberado.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final canPost = await ref.read(reminderScheduleProvider).canPost();
    if (mounted && canPost != _canPost) setState(() => _canPost = canPost);
  }

  /// Ligar sem permissão de notificar já pede a permissão: chave ligada que
  /// não avisa nada seria promessa vazia.
  void _set(bool enabled) {
    ref.read(remindersEnabledProvider.notifier).set(enabled: enabled);
    if (enabled && !_canPost) {
      unawaited(ref.read(reminderScheduleProvider).allowPosting());
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(reminderScheduleProvider);
    if (!schedule.isSupported) return const SizedBox.shrink();
    final enabled = ref.watch(remindersEnabledProvider);
    final blocked = enabled && !_canPost;
    return CajuiListRow(
      title: DueRemindersRow.title,
      subtitle: _subtitle(enabled: enabled, blocked: blocked),
      trailing: CajuiSwitch(
        value: enabled,
        semanticLabel: DueRemindersRow.title,
        onChanged: _set,
      ),
      onPressed: blocked ? schedule.allowPosting : null,
      semanticLabel: blocked
          ? '${DueRemindersRow.title}, liberar as notificações do Cajui'
          : null,
    );
  }

  static String _subtitle({required bool enabled, required bool blocked}) {
    if (!enabled) return 'Desligado: nenhum aviso de conta a vencer';
    if (blocked) {
      return 'O Android está segurando as notificações do Cajui. Toque '
          'para liberar.';
    }
    return 'Dois dias antes e no dia, às 9h: contas, parcelas e faturas em '
        'aberto';
  }
}
