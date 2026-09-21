import 'package:cajui/src/app/home_tab.dart';
import 'package:cajui/src/app/home_tab_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O painel do mês.
///
/// Os indicadores chegam com a feature do painel. Até lá a tela diz a
/// verdade — não há o que mostrar — e aponta o primeiro passo, em vez de
/// exibir números de enfeite.
class DashboardPage extends ConsumerWidget {
  /// Cria o painel.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CajuiScreen(
      title: 'Painel',
      children: [
        CajuiEmptyState(
          illustration: const CajuiHeroFruit(),
          title: 'O mês aparece aqui',
          message:
              'Sobra, limite da semana e o que vence entram nesta tela '
              'conforme você lança. Comece pelo primeiro lançamento.',
          action: CajuiNoticeAction(
            label: 'Ver lançamentos',
            onPressed: () =>
                ref.read(homeTabProvider.notifier).select(HomeTab.entries),
          ),
        ),
      ],
    );
  }
}
