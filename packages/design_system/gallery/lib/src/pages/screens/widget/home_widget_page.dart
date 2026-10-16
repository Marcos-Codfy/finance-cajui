import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/shared/screen_state_page.dart';
import 'package:gallery/src/pages/screens/shared/screen_variant.dart';
import 'package:gallery/src/pages/screens/widget/widget_demo.dart';

/// O widget da tela inicial: vidro sobre a aurora, e o app que nasce dele.
class HomeWidgetPage extends StatelessWidget {
  /// Cria a página do widget, aberta no estado [initialIndex].
  const new({this.initialIndex = 0, super.key});

  /// O estado aberto ao entrar: a vitrine de estados abre direto no que
  /// foi tocado.
  final int initialIndex;

  /// O nome da tela, o mesmo do menu.
  static const title = 'Widget da tela inicial';

  /// O papel da tela no app.
  static const lead =
      'A sobra do mês na tela inicial, num painel de vidro sobre a aurora '
      'do Cerrado à noite. Tocar no número abre o Cajui de dentro do '
      'widget; o "+" abre direto o novo lançamento.';

  @override
  Widget build(BuildContext context) {
    return ScreenStatePage(
      title: title,
      lead: lead,
      variants: variants(),
      initialIndex: initialIndex,
    );
  }

  /// Os estados, na ordem do seletor. Ficam fora do `build` para que a
  /// vitrine de estados mostre exatamente os mesmos, lado a lado.
  static List<ScreenVariant> variants() => [
    ScreenVariant(
      label: 'Na tela inicial',
      note:
          'Toque no número: o app cresce do widget (Android 12+) e o '
          'Início recebe os números pelo vidro, com o pop do card.',
      builder: (_) => const WidgetDemo(),
    ),
    ScreenVariant(
      label: 'Mês novo',
      note:
          'Passado o mês do número, o widget não o mostra: pede para '
          'abrir o app, que publica o novo.',
      builder: (_) => const WidgetDemo(stale: true),
    ),
  ];
}
