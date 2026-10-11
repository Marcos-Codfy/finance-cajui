import 'package:design_system/design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Um celular de mentira: arrastar o dedo aqui inclina o que estiver ligado
/// ao mesmo [tilt], e soltar o devolve ao repouso.
///
/// A gallery roda no navegador, onde não há giroscópio, e o design system
/// não lê sensor de propósito: a inclinação entra de fora. No app, quem
/// alimenta o `CajuiTilt` é o acelerômetro; aqui, é este quadrado.
class TiltPad extends StatelessWidget {
  /// Cria o quadrado que escreve em [tilt].
  const new({required this.tilt, super.key});

  /// A inclinação de mentira, de -1 a 1 em cada eixo.
  final ValueNotifier<Offset> tilt;

  static const double _side = 112;

  void _move(Offset local) {
    tilt.value = Offset(
      (local.dx / _side * 2 - 1).clamp(-1, 1).toDouble(),
      (local.dy / _side * 2 - 1).clamp(-1, 1).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Semantics(
      label: 'Inclinação de mentira: arraste para inclinar',
      child: RawGestureDetector(
        // Ganha o dedo na hora: senão a rolagem da página levaria o arrasto.
        gestures: {
          EagerGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                EagerGestureRecognizer.new,
                (_) {},
              ),
        },
        child: Listener(
          onPointerDown: (event) => _move(event.localPosition),
          onPointerMove: (event) => _move(event.localPosition),
          onPointerUp: (_) => tilt.value = Offset.zero,
          onPointerCancel: (_) => tilt.value = Offset.zero,
          child: SizedBox.square(
            dimension: _side,
            child: ValueListenableBuilder<Offset>(
              valueListenable: tilt,
              builder: (context, value, _) => _pad(theme, value),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pad(CajuiThemeData theme, Offset value) {
    final colors = theme.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.sunken,
        borderRadius: const BorderRadius.all(CajuiRadius.md),
        border: Border.all(color: colors.border.field),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment(value.dx, value.dy),
            child: _dot(colors.action.primary),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: CajuiSpacing.xs),
              child: Text(
                'arraste',
                style: theme.typography.caption.copyWith(
                  color: colors.text.faint,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A bolinha que mostra para onde o celular de mentira está inclinado.
  Widget _dot(Color color) {
    return Padding(
      padding: const EdgeInsets.all(CajuiSpacing.sm),
      child: SizedBox.square(
        dimension: 20,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
