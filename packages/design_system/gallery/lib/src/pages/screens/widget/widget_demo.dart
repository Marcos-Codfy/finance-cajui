import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/home/home_numbers.dart';
import 'package:gallery/src/pages/screens/shared/mock_screen.dart';
import 'package:gallery/src/pages/screens/widget/glass_widget.dart';

/// O gesto inteiro, de verdade: a tela inicial do celular com o widget, e o
/// toque no número abrindo o Cajui.
///
/// O app cresce de dentro do widget, como o Android 12+ faz quando o widget
/// tem o fundo marcado, e o Início recebe os números atravessando o vidro
/// (`CajuiGlassArrival`). "Voltar à tela inicial" fecha o app, e o toque
/// pode ser repetido.
class WidgetDemo extends StatefulWidget {
  /// Cria a demonstração; com [stale], o widget é o de mês novo.
  const new({this.stale = false, super.key});

  /// O widget do mês que virou, antes de o app publicar o novo.
  final bool stale;

  @override
  State<WidgetDemo> createState() => _WidgetDemoState();
}

class _WidgetDemoState extends State<WidgetDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _launch = AnimationController(
    vsync: this,
    duration: CajuiDurations.slow,
  );
  int _arrival = 0;

  @override
  void dispose() {
    _launch.dispose();
    super.dispose();
  }

  void _open() {
    setState(() => _arrival++);
    _launch.forward(from: 0);
  }

  void _close() => _launch.reverse();

  @override
  Widget build(BuildContext context) {
    final colors = CajuiTheme.of(context).colors;
    return Stack(
      children: [
        Positioned.fill(child: _homeScreen(colors)),
        AnimatedBuilder(
          animation: _launch,
          builder: (context, app) =>
              _launch.value == 0 ? const SizedBox.shrink() : _growing(app!),
          child: ColoredBox(color: colors.surface.base, child: _app()),
        ),
      ],
    );
  }

  /// A tela inicial: um papel de parede de noite e o widget no alto.
  ///
  /// Num fundo claro o vidro não tinha o que mostrar, e a página prometia
  /// "a aurora do Cerrado à noite" sobre um bege. O céu é o mesmo da aurora
  /// (`brand.auroraSky`), de baixo para cima, como um céu escurecendo.
  Widget _homeScreen(CajuiColors colors) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: colors.brand.auroraSky,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        CajuiSpacing.md,
        CajuiSpacing.xl,
        CajuiSpacing.md,
        0,
      ),
      child: Align(alignment: Alignment.topCenter, child: _widget()),
    ),
  );

  Widget _widget() => widget.stale
      ? const GlassWidget(
          label: 'Mês novo',
          amount: r'R$ —',
          caption: 'Abra o Cajui para ver o mês.',
        )
      : GlassWidget(
          label: 'Sobra de outubro',
          amount: BrlFormatter.format(HomeNumbers.leftover),
          caption: 'Depois de pagar tudo, pelo que está lançado.',
          onNumber: _open,
        );

  /// O app crescendo de dentro do widget: parte do tamanho dele, no alto,
  /// e ocupa a tela.
  Widget _growing(Widget app) {
    final t = CajuiCurves.enter.transform(_launch.value);
    return Opacity(
      opacity: t.clamp(0, 1),
      child: Transform.scale(
        alignment: const Alignment(0, -0.72),
        scale: 0.36 + 0.64 * t,
        child: app,
      ),
    );
  }

  Widget _app() => MockScreen(
    title: 'Outubro',
    footer: CajuiButton(
      label: 'Voltar à tela inicial',
      variant: CajuiButtonVariant.secondary,
      expand: true,
      onPressed: _close,
    ),
    children: [
      CajuiGlassArrival(
        arrival: _arrival,
        child: HomeNumbers.carousel(HomeNumbers.closing()),
      ),
    ],
  );
}
