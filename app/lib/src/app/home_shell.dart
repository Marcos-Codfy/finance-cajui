import 'package:cajui/src/app/home_tab.dart';
import 'package:cajui/src/app/home_tab_controller.dart';
import 'package:cajui/src/features/assistant/presentation/assistant_page.dart';
import 'package:cajui/src/features/dashboard/presentation/dashboard_page.dart';
import 'package:cajui/src/features/ledger/presentation/entries_page.dart';
import 'package:cajui/src/features/settings/presentation/settings_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A casca do app: a área em vigor em cima, a barra de navegação embaixo.
class HomeShell extends ConsumerWidget {
  /// Cria a casca.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(homeTabProvider);
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
        CajuiNavBar(
          destinations: [for (final tab in HomeTab.values) tab.destination],
          selectedIndex: current.index,
          onSelected: (index) =>
              ref.read(homeTabProvider.notifier).select(HomeTab.values[index]),
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
