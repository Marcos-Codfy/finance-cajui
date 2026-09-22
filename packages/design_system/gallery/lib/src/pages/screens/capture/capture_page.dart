import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/capture/capture_screen.dart';
import 'package:gallery/src/pages/screens/capture/capture_state.dart';
import 'package:gallery/src/pages/screens/shared/screen_state_page.dart';
import 'package:gallery/src/pages/screens/shared/screen_variant.dart';

/// A confirmação de captura, nos 18 estados do fluxo de captura.
class CapturePage extends StatelessWidget {
  /// Cria a página da captura.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenStatePage(
      title: 'Confirmação de captura',
      lead:
          'O fluxo mais importante do app: um comprovante fotografado ou '
          'compartilhado de qualquer lugar vira lançamento. Cupom de papel '
          'entra pela câmera (ADR-017), arquivo entra pelo compartilhamento, '
          'e daí em diante o caminho é o mesmo. Cada coisa que pode dar '
          'errado tem o seu próprio texto e a sua própria saída.',
      variants: [
        for (final state in CaptureState.values)
          ScreenVariant(
            label: state.label,
            note: state.note,
            builder: (_) => CaptureScreen(state),
          ),
      ],
    );
  }
}
