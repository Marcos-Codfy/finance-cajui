import 'package:cajui/src/app/home_tab.dart';
import 'package:cajui/src/app/home_tab_controller.dart';
import 'package:cajui/src/features/assistant/presentation/assistant_page.dart';
import 'package:cajui/src/features/home/presentation/home_page.dart';
import 'package:cajui/src/features/home_widget/presentation/widget_arrival.dart';
import 'package:cajui/src/features/receipts/presentation/capture_page.dart';
import 'package:cajui/src/features/receipts/presentation/capture_state.dart';
import 'package:cajui/src/features/receipts/presentation/capture_view_model.dart';
import 'package:cajui/src/features/statements/presentation/statement_talk_state.dart';
import 'package:cajui/src/features/statements/presentation/statement_talk_view_model.dart';
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
    _follow(context, ref);
    final capturing = ref.watch(captureProvider) is! CaptureIdle;
    return Stack(
      children: [
        // A casca continua montada por baixo: as abas guardam a conversa e
        // a rolagem de quando o comprovante chegou.
        ExcludeSemantics(
          excluding: capturing,
          child: _areas(context, ref, capturing: capturing),
        ),
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

  /// O que leva a pessoa até a tela certa quando algo chega.
  void _follow(BuildContext context, WidgetRef ref) {
    ref.listen(captureProvider, (before, now) {
      // A conferência mora na casca, e as telas abertas pelo Início ficam
      // empilhadas por cima dela: sem fechá-las, a foto tirada em
      // "Lançamentos" abriria a conferência escondida atrás da tela.
      if (now is CaptureIdle || (before != null && before is! CaptureIdle)) {
        return;
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
    // O extrato que chega abre na conversa da Juju (RN-1100): a casca leva
    // a pessoa até lá, de qualquer aba e de qualquer tela empilhada.
    ref.listen(statementTalkProvider, (before, now) {
      if (before is! StatementTalkIdle || now is StatementTalkIdle) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      ref.read(homeTabProvider.notifier).select(HomeTab.conversar);
    });
    // O número do widget abre o Início, com a chegada pelo vidro.
    ref.listen(widgetArrivalProvider, (before, now) {
      if (now == 0 || now == before) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      ref.read(homeTabProvider.notifier).select(HomeTab.inicio);
    });
  }

  Widget _areas(
    BuildContext context,
    WidgetRef ref, {
    required bool capturing,
  }) {
    final current = ref.watch(homeTabProvider);
    // Com o teclado aberto, a barra sai: ela ocuparia a altura que falta
    // para ver o que se está escrevendo. Quem digita já escolheu onde está.
    final typing = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Column(
      children: [
        Expanded(
          // Pilha, e não troca de widget: cada área guarda onde a rolagem
          // estava e o que foi digitado quando a pessoa vai e volta.
          child: _stack(current, capturing: capturing),
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

  /// As abas empilhadas, e a troca entre elas é a câmera orbitando de uma
  /// para a outra (`CajuiOrbitStack`), que guarda o estado das duas como o
  /// `IndexedStack` guardava. A escondida não fica com o relógio de quadros
  /// ligado: o Início atrás da conversa fazia a festa do mês sem ninguém
  /// ver.
  Widget _stack(HomeTab current, {required bool capturing}) => CajuiOrbitStack(
    index: current.index,
    children: [
      for (final tab in HomeTab.values)
        TickerMode(enabled: tab == current && !capturing, child: _page(tab)),
    ],
  );

  Widget _page(HomeTab tab) => switch (tab) {
    HomeTab.conversar => const AssistantPage(),
    HomeTab.inicio => const HomePage(),
  };
}
