import 'dart:async';

import 'package:cajui/src/features/home_widget/application/home_widget_providers.dart';
import 'package:cajui/src/features/home_widget/application/widget_placement.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A linha de Ajustes que põe o widget na tela inicial (ADR-025).
///
/// O dono pediu o botão: pôr widget à mão no Android são três passos que
/// ninguém descobre sozinho. Um toque aqui pede ao launcher, e o sistema
/// mostra a confirmação com a prévia do widget. Como a confirmação é do
/// sistema, a linha confere de novo quando o app volta dela.
class HomeWidgetRow extends ConsumerStatefulWidget {
  /// Cria a linha.
  const new({super.key});

  @override
  ConsumerState<HomeWidgetRow> createState() => _HomeWidgetRowState();
}

class _HomeWidgetRowState extends ConsumerState<HomeWidgetRow>
    with WidgetsBindingObserver {
  WidgetPlacement _placement = WidgetPlacement.unavailable;

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final placement = await ref.read(homeScreenProvider).placement();
    if (mounted && placement != _placement) {
      setState(() => _placement = placement);
    }
  }

  Future<void> _pin() async {
    await ref.read(homeScreenProvider).pin();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) => switch (_placement) {
    WidgetPlacement.unavailable => const SizedBox.shrink(),
    WidgetPlacement.absent => _row(
      context,
      subtitle: 'A sobra do mês na tela do celular, sem abrir o app.',
      status: 'Pôr na tela',
      onPressed: _pin,
    ),
    WidgetPlacement.placed => _row(
      context,
      subtitle:
          'Já está na tela inicial. Para tirar, toque e segure nele e '
          'escolha remover.',
      status: 'Na tela',
    ),
    WidgetPlacement.manual => _row(
      context,
      subtitle:
          'Toque e segure num espaço vazio da tela inicial, abra Widgets '
          'e arraste o Cajui.',
      status: 'À mão',
    ),
  };

  Widget _row(
    BuildContext context, {
    required String subtitle,
    required String status,
    VoidCallback? onPressed,
  }) {
    final theme = CajuiTheme.of(context);
    return CajuiListRow(
      title: 'Widget na tela inicial',
      subtitle: subtitle,
      trailing: Text(
        status,
        style: theme.typography.label.copyWith(
          color: onPressed == null
              ? theme.colors.text.muted
              : theme.colors.action.primary,
        ),
      ),
      semanticLabel: 'Widget na tela inicial, $status',
      onPressed: onPressed,
    );
  }
}
