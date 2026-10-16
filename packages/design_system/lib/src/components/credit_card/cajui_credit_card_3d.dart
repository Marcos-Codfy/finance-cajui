import 'dart:async';
import 'dart:math' as math;

import 'package:design_system/src/components/credit_card/cajui_card_skin.dart';
import 'package:design_system/src/components/credit_card/card_limit_usage.dart';
import 'package:design_system/src/components/credit_card/card_tilt_motion.dart';
import 'package:design_system/src/components/credit_card/credit_card_back.dart';
import 'package:design_system/src/components/credit_card/credit_card_front.dart';
import 'package:design_system/src/interaction/cajui_pressable.dart';
import 'package:design_system/src/interaction/cajui_touch.dart';
import 'package:design_system/src/motion/cajui_tilt.dart';
import 'package:design_system/src/motion/frame_clock.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_curves.dart';
import 'package:design_system/src/tokens/primitives/cajui_depth.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:flutter/widgets.dart';

/// O cartão de crédito em 3D: inclina com o celular ou com o dedo, tem um
/// brilho que anda, e um toque o vira para mostrar o limite.
///
/// Na frente, o que identifica o cartão; no verso, quanto do limite está em
/// uso, quanto está livre, a barra e a frase. Cartão é forma de pagamento,
/// nunca despesa: nada aqui fala em "gasto".
///
/// O leitor de tela ouve um botão só, com o lado que está à mostra por
/// extenso — inclusive o percentual e a frase do verso. A inclinação é
/// enfeite: some sem perda nenhuma.
///
/// No movimento reduzido o cartão fica reto, o brilho parado, e virar é uma
/// fusão curta entre os dois lados.
class CajuiCreditCard3D extends StatefulWidget {
  /// Cria o cartão [name], com [detail] na frente e [usedCents] em uso de um
  /// limite de [limitCents].
  const new({
    required this.name,
    required this.detail,
    required this.usedCents,
    required this.limitCents,
    this.tilt,
    this.onFlip,
    this.skin = CajuiCardSkin.cajui,
    super.key,
  });

  /// O nome do cartão, como a pessoa o chama: "Cartão Ipê".
  final String name;

  /// A linha da frente: "fecha dia 25 · vence dia 5". Nunca o número do
  /// cartão — o Cajui não o guarda.
  final String detail;

  /// O que está em uso do limite, em centavos.
  final int usedCents;

  /// O limite, em centavos. Maior que zero.
  final int limitCents;

  /// A inclinação do aparelho, lida pelo app. Sem ela, só o dedo inclina.
  final CajuiTilt? tilt;

  /// Avisa quando o cartão vira: `true` ao mostrar o verso.
  final ValueChanged<bool>? onFlip;

  /// A cor do plástico, escolhida pela pessoa.
  final CajuiCardSkin skin;

  @override
  State<CajuiCreditCard3D> createState() => _CajuiCreditCard3DState();
}

class _CajuiCreditCard3DState extends State<CajuiCreditCard3D>
    with TickerProviderStateMixin {
  /// A proporção do cartão de verdade (ISO/IEC 7810, 85,6 × 54 mm).
  static const double _ratio = 1.586;
  static const double _maxWidth = 360;

  /// A inclinação máxima, uns 14°: o bastante para o brilho andar, pouco
  /// para o texto deformar.
  static const double _maxAngle = 0.24;

  /// A lente do design system: a mesma do carrossel e da rolagem.
  static const double _perspective = CajuiDepth.perspective;

  final CardTiltMotion _tilt = CardTiltMotion();
  late final FrameClock _clock = FrameClock(vsync: this, onFrame: _tilt.step);
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: CajuiDurations.slow,
  );

  /// A mola passa um pouco do meio giro e volta: o cartão "assenta".
  late final Animation<double> _turn = CurvedAnimation(
    parent: _flip,
    curve: CajuiCurves.spring,
    reverseCurve: CajuiCurves.spring.flipped,
  );
  bool _back = false;
  bool _alive = false;

  @override
  void initState() {
    super.initState();
    widget.tilt?.addListener(_onSensor);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _alive = CajuiTheme.of(context).motionLevel.allowsSpring;
    if (_alive) return;
    _clock.sleep();
    _tilt.settle();
    _flip.value = _back ? 1 : 0;
  }

  @override
  void didUpdateWidget(CajuiCreditCard3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tilt == widget.tilt) return;
    oldWidget.tilt?.removeListener(_onSensor);
    widget.tilt?.addListener(_onSensor);
  }

  @override
  void dispose() {
    widget.tilt?.removeListener(_onSensor);
    _clock.dispose();
    _flip.dispose();
    _tilt.dispose();
    super.dispose();
  }

  void _onSensor() {
    final tilt = widget.tilt;
    if (!_alive || tilt == null) return;
    _tilt.sense(tilt.value);
    _clock.wake();
  }

  /// O dedo em [local] vira uma inclinação de -1 a 1: a borda tocada afunda.
  void _hold(Offset local, double width) {
    if (!_alive) return;
    final height = width / _ratio;
    _tilt.hold(Offset(local.dx / width * 2 - 1, local.dy / height * 2 - 1));
    _clock.wake();
  }

  void _release() {
    if (!_alive) return;
    _tilt.release();
    _clock.wake();
  }

  void _toggle() {
    setState(() => _back = !_back);
    if (_alive) unawaited(_back ? _flip.forward() : _flip.reverse());
    widget.onFlip?.call(_back);
  }

  @override
  Widget build(BuildContext context) {
    final usage = CardLimitUsage(
      usedCents: widget.usedCents,
      limitCents: widget.limitCents,
    );
    final spoken = _back
        ? 'Limite do ${widget.name}: ${usage.spoken}. Toque para voltar.'
        : '${widget.name}, ${widget.detail}. '
              'Toque para ver o limite.';
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _maxWidth),
      child: LayoutBuilder(
        builder: (context, constraints) => CajuiPressable(
          onPressed: _toggle,
          touch: CajuiTouch.card,
          semanticLabel: spoken,
          radius: CreditCardFront.radius,
          builder: (context, _) => _card(constraints.maxWidth, usage),
        ),
      ),
    );
  }

  /// Os dois lados, invisíveis, dão a altura: com fonte grande, o cartão
  /// cresce em vez de cortar texto, e os dois lados ficam do mesmo tamanho.
  ///
  /// Só o arrasto de lado inclina: o de cima para baixo continua rolando a
  /// tela, e o toque continua virando o cartão. Enfeite nunca disputa o dedo
  /// com o que a pessoa quer fazer.
  Widget _card(double width, CardLimitUsage usage) {
    final height = width / _ratio;
    return GestureDetector(
      excludeFromSemantics: true,
      onHorizontalDragStart: (drag) => _hold(drag.localPosition, width),
      onHorizontalDragUpdate: (drag) => _hold(drag.localPosition, width),
      onHorizontalDragEnd: (_) => _release(),
      onHorizontalDragCancel: _release,
      child: SizedBox(
        width: width,
        child: Stack(
          children: [
            _sizer(_front(Alignment.center), height),
            _sizer(_backFace(usage, Alignment.center), height),
            Positioned.fill(child: _alive ? _turning(usage) : _calm(usage)),
          ],
        ),
      ),
    );
  }

  Widget _sizer(Widget face, double height) => Visibility(
    visible: false,
    maintainState: true,
    maintainAnimation: true,
    maintainSize: true,
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: face,
    ),
  );

  Widget _front(Alignment light) => CreditCardFront(
    name: widget.name,
    detail: widget.detail,
    light: light,
    skin: widget.skin,
  );

  Widget _backFace(CardLimitUsage usage, Alignment light) =>
      CreditCardBack(name: widget.name, usage: usage, light: light);

  /// A luz anda ao contrário da inclinação, a partir do alto à esquerda.
  static Alignment _light(Offset tilt) =>
      Alignment(-0.5 - tilt.dx * 0.9, -0.7 - tilt.dy * 0.9);

  Widget _turning(CardLimitUsage usage) {
    return AnimatedBuilder(
      animation: Listenable.merge([_turn, _tilt]),
      builder: (context, _) {
        final tilt = _tilt.tilt;
        final turn = _turn.value * math.pi;
        final light = _light(tilt);
        // O verso é desenhado já espelhado, para ler direito depois do meio
        // giro; a luz, que é do mundo, espelha junto.
        final face = math.cos(turn) < 0
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(math.pi),
                child: _backFace(usage, Alignment(-light.x, light.y)),
              )
            : _front(light);
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, _perspective)
            ..rotateX(tilt.dy * _maxAngle)
            ..rotateY(-tilt.dx * _maxAngle + turn),
          child: face,
        );
      },
    );
  }

  Widget _calm(CardLimitUsage usage) {
    const light = Alignment(-0.5, -0.7);
    return AnimatedSwitcher(
      duration: CajuiDurations.reducedFade,
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, ?current]),
      child: KeyedSubtree(
        key: ValueKey(_back),
        child: _back ? _backFace(usage, light) : _front(light),
      ),
    );
  }
}
