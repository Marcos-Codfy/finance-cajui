import 'package:cajui/src/app/home_tab.dart';
import 'package:cajui/src/app/home_tab_controller.dart';
import 'package:cajui/src/features/assistant/presentation/assistant_page.dart';
import 'package:cajui/src/features/dashboard/presentation/dashboard_page.dart';
import 'package:cajui/src/features/ledger/presentation/entries_page.dart';
import 'package:cajui/src/features/receipts/presentation/capture_page.dart';
import 'package:cajui/src/features/receipts/presentation/capture_state.dart';
import 'package:cajui/src/features/receipts/presentation/capture_view_model.dart';
import 'package:cajui/src/features/settings/presentation/settings_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A casca do app: a área em vigor em cima, a barra de navegação embaixo —
/// e, por cima de tudo, a captura, quando chega um comprovante.
class HomeShell extends ConsumerWidget {
  /// Cria a casca.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capturing = ref.watch(captureProvider) is! CaptureIdle;
    return Stack(
      children: [
        // A casca continua montada por baixo: quem estava no meio de algo
        // volta para onde estava depois de conferir o comprovante.
        ExcludeSemantics(excluding: capturing, child: _areas(context, ref)),
        if (capturing)
          Positioned.fill(
            child: ColoredBox(
              color: CajuiTheme.of(context).colors.surface.base,
              child: const CapturePage(),
            ),
          ),
      ],
    );
  }

  Widget _areas(BuildContext context, WidgetRef ref) {
    final current = ref.watch(homeTabProvider);
    // Com o teclado aberto, a barra sai: são quatro destinos ocupando a
    // altura que falta para ver o que se está escrevendo. Quem digita já
    // escolheu onde está.
    final typing = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Column(
      children: [
        Expanded(
          // Pilha, e não troca de widget: cada área guarda onde a rolagem
          // estava e o que foi digitado quando a pessoa vai e volta.
          child: IndexedStack(
            index: current.index,
            children: [for (final tab in HomeTab.values) _page(tab)],
          ),
        ),
        if (!typing)
          CajuiNavBar(
            destinations: [for (final tab in HomeTab.values) tab.destination],
            selectedIndex: current.index,
            onSelected: (index) => ref
                .read(homeTabProvider.notifier)
                .select(HomeTab.values[index]),
          ),
      ],
    );
  }

  Widget _page(HomeTab tab) => switch (tab) {
    HomeTab.dashboard => const DashboardPage(),
    HomeTab.entries => const EntriesPage(),
    HomeTab.assistant => const AssistantPage(),
    HomeTab.settings => const SettingsPage(),
  };
}
