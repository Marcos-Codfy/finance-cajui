import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/capture/capture_screen.dart';
import 'package:gallery/src/pages/screens/capture/capture_state.dart';
import 'package:gallery/src/pages/screens/shared/screen_state_page.dart';
import 'package:gallery/src/pages/screens/shared/screen_variant.dart';

/// O comprovante, nos 18 estados do fluxo de captura.
class CapturePage extends StatelessWidget {
  /// Cria a página do comprovante, aberta no estado [initialIndex] — ou,
  /// sem ele, em [opening].
  const new({this.initialIndex, super.key});

  /// O estado aberto ao entrar: a vitrine de estados abre direto no que
  /// foi tocado.
  final int? initialIndex;

  /// O nome da tela, o mesmo do menu.
  static const title = 'Comprovante';

  /// O papel da tela no app.
  static const lead =
      'O fluxo mais importante do app: um comprovante fotografado ou '
      'compartilhado de qualquer lugar vira lançamento, e cada coisa que '
      'pode dar errado tem o seu próprio texto e a sua própria saída.';

  /// A página abre em "Confirmando", a tela mais completa do fluxo. O
  /// primeiro estado, "Fotografando", é quase só a câmera, e quem chegava
  /// achava que a página estava vazia. A ordem do seletor continua a do
  /// fluxo.
  static int get opening => CaptureState.confirming.index;

  @override
  Widget build(BuildContext context) {
    return ScreenStatePage(
      title: title,
      lead: lead,
      variants: variants(),
      initialIndex: initialIndex ?? opening,
    );
  }

  /// Os estados, na ordem do fluxo. Ficam fora do `build` para que a
  /// vitrine de estados mostre exatamente os mesmos, lado a lado.
  static List<ScreenVariant> variants() => [
    for (final state in CaptureState.values)
      ScreenVariant(
        label: state.label,
        note: state.note,
        builder: (_) => CaptureScreen(state),
      ),
  ];
}
