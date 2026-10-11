import 'package:design_system/src/components/wallet/render_wallet_stack.dart';
import 'package:design_system/src/motion/cinematic_timeline.dart';
import 'package:design_system/src/motion/motion_level.dart';
import 'package:design_system/src/motion/motion_of.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// A pilha de carteira: cartões empilhados em 3D que se abrem em leque.
///
/// Feita para a tela de Cartões, com o `CajuiCreditCard3D` dentro — mas
/// aceita qualquer bloco. Três movimentos, todos de pintura:
///
/// 1. **Ao aparecer**, os cartões saem de um maço, um de cada vez, o da
///    frente primeiro, e assentam em coluna (dentro dos 600 ms do teto).
///    Dentro de uma `CajuiCinematicEntrance`, o maço abre no ritmo dela.
/// 2. **Rolando para baixo**, cada cartão que chega ao alto da tela para ali
///    e é coberto pelo seguinte: a carteira se fecha conforme se rola, e se
///    abre de novo na volta.
/// 3. **Puxando além do topo**, os cartões se afastam uns dos outros, em
///    leque — com a física que quica, da `CajuiDepthScroll`.
///
/// Parada e à vista, a pilha é uma coluna comum: todo cartão inteiro, plano,
/// tocável, e na ordem certa para o leitor de tela. O movimento só acontece
/// enquanto algo se move. No `reduced`, é só a coluna.
class CajuiWalletStack extends StatefulWidget {
  /// Empilha os cartões [children], de cima para baixo.
  const new({
    required this.children,
    this.gap = CajuiSpacing.md,
    this.dealOnAppear = true,
    super.key,
  });

  /// Os cartões.
  final List<Widget> children;

  /// O espaço entre um cartão e o seguinte, com a pilha aberta.
  final double gap;

  /// Se o maço se abre ao aparecer. Desligue quando a pilha já estava à
  /// vista e só mudou de conteúdo.
  final bool dealOnAppear;

  @override
  State<CajuiWalletStack> createState() => _CajuiWalletStackState();
}

class _CajuiWalletStackState extends State<CajuiWalletStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _deal = AnimationController(
    vsync: this,
    duration: CajuiDurations.slowest,
    value: widget.dealOnAppear ? 0 : 1,
  );
  bool _settled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dealWhenVisible();
  }

  /// O maço só se abre com a tela à vista; numa entrada cinematográfica,
  /// quem manda é o relógio dela, e o próprio fica parado.
  void _dealWhenVisible() {
    if (_settled || CinematicTimeline.maybeOf(context) != null) return;
    if (motionOf(context) == MotionLevel.reduced) {
      _settled = true;
      _deal.value = 1;
      return;
    }
    if (!TickerMode.valuesOf(context).enabled) return;
    _settled = true;
    if (_deal.value < 1) _deal.forward();
  }

  @override
  void dispose() {
    _deal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = CinematicTimeline.maybeOf(context);
    return _WalletLayout(
      gap: widget.gap,
      deal: widget.dealOnAppear ? scene?.progress ?? _deal : _deal,
      motion: motionOf(context),
      position: Scrollable.maybeOf(context)?.position,
      children: [
        for (final card in widget.children) RepaintBoundary(child: card),
      ],
    );
  }
}

class _WalletLayout extends MultiChildRenderObjectWidget {
  const new({
    required this.gap,
    required this.deal,
    required this.motion,
    required this.position,
    required super.children,
  });

  final double gap;
  final Animation<double> deal;
  final MotionLevel motion;
  final ScrollPosition? position;

  @override
  RenderWalletStack createRenderObject(BuildContext context) =>
      RenderWalletStack(
        gap: gap,
        deal: deal,
        motion: motion,
        position: position,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderWalletStack renderObject,
  ) {
    renderObject
      ..gap = gap
      ..deal = deal
      ..motion = motion
      ..position = position;
  }
}
