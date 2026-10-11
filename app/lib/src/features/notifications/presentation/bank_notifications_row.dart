import 'dart:async';

import 'package:cajui/src/features/notifications/application/notification_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A linha de Ajustes que liga o lançamento pelas notificações do banco
/// (RN-786).
///
/// Diz em uma frase o que acontece e se está ligado. Ligar é dar o acesso
/// às notificações na tela do sistema — o Cajui não guarda chave própria,
/// e por isso a linha confere de novo toda vez que o app volta de lá.
/// Fica num arquivo só dela: os Ajustes vão mudar de lugar, e ela vai
/// junto sem levar nada do resto.
class BankNotificationsRow extends ConsumerStatefulWidget {
  /// Cria a linha.
  const new({super.key});

  @override
  ConsumerState<BankNotificationsRow> createState() =>
      _BankNotificationsRowState();
}

class _BankNotificationsRowState extends ConsumerState<BankNotificationsRow>
    with WidgetsBindingObserver {
  bool _granted = false;

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

  /// A pessoa volta da tela do sistema com o app em segundo plano: é na
  /// volta que a linha descobre se ela ligou.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final granted = await ref.read(notificationAccessProvider).isGranted();
    if (mounted && granted != _granted) setState(() => _granted = granted);
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(notificationAccessProvider);
    if (!access.isSupported) return const SizedBox.shrink();
    final theme = CajuiTheme.of(context);
    final status = _granted ? 'Ligado' : 'Desligado';
    return CajuiListRow(
      title: 'Lançar pelas notificações do banco',
      subtitle: _granted
          ? 'Compra e Pix avisados pelo banco entram sozinhos, e dá para '
                'desfazer na hora.'
          : 'Quando o banco avisar de uma compra ou de um Pix, o Cajui '
                'lança sozinho e você pode desfazer.',
      trailing: Text(
        status,
        style: theme.typography.label.copyWith(color: theme.colors.text.muted),
      ),
      semanticLabel: 'Lançar pelas notificações do banco, $status, abrir',
      onPressed: access.openSettings,
    );
  }
}
