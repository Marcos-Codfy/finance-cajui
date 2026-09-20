import 'package:design_system/src/feedback/cajui_feedback_scope.dart';
import 'package:design_system/src/interaction/focus_ring.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_curves.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Monta a aparência de um controle a partir dos estados em que ele está.
typedef PressableBuilder =
    Widget Function(BuildContext context, Set<WidgetState> states);

/// A base de todo controle tocável do Cajui: botão, chip, chave, cartão.
///
/// Concentra o que nenhum componente deveria reimplementar — e que some
/// primeiro quando alguém monta um controle do zero: foco e ativação por
/// teclado, anel de foco, semântica para leitor de tela, alvo de toque de
/// 48 dp, resposta em mola e o aviso sonoro e tátil.
class CajuiPressable extends StatefulWidget {
  /// Cria um controle tocável cuja aparência vem de [builder].
  const new({
    required this.builder,
    required this.onPressed,
    required this.semanticLabel,
    this.radius = BorderRadius.zero,
    this.toggled,
    this.busy = false,
    this.autofocus = false,
    super.key,
  });

  /// Desenha o controle conforme os estados.
  final PressableBuilder builder;

  /// O que acontece ao ativar. `null` desabilita o controle.
  final VoidCallback? onPressed;

  /// O nome do controle para o leitor de tela.
  final String semanticLabel;

  /// O raio de canto, que o anel de foco acompanha.
  final BorderRadius radius;

  /// Para chave e chip selecionável: ligado ou desligado. `null` em botão.
  final bool? toggled;

  /// Ocupado: continua visível e focável, mas não dispara de novo.
  final bool busy;

  /// Se recebe o foco ao aparecer.
  final bool autofocus;

  @override
  State<CajuiPressable> createState() => _CajuiPressableState();
}

class _CajuiPressableState extends State<CajuiPressable> {
  final Set<WidgetState> _states = {};
  bool _keyboardFocus = false;

  bool get _enabled => widget.onPressed != null;

  void _set(WidgetState state, {required bool active}) {
    final changed = active ? _states.add(state) : _states.remove(state);
    if (changed && mounted) setState(() {});
  }

  void _activate() {
    if (!_enabled || widget.busy) return;
    final feedback = CajuiFeedbackScope.of(context);
    final toggled = widget.toggled;
    toggled == null ? feedback.tap() : feedback.toggle(on: !toggled);
    widget.onPressed!();
  }

  Set<WidgetState> get _visibleStates => {
    ..._states,
    if (!_enabled) WidgetState.disabled,
    if (widget.toggled ?? false) WidgetState.selected,
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: widget.toggled == null,
      enabled: _enabled,
      toggled: widget.toggled,
      label: widget.semanticLabel,
      // O gesto fica fora da semântica para não virar um segundo nó; quem
      // entrega a ação de tocar ao leitor de tela é este.
      onTap: _enabled ? _activate : null,
      child: FocusableActionDetector(
        enabled: _enabled,
        autofocus: widget.autofocus,
        mouseCursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
        shortcuts: _activationKeys,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => _activate(),
          ),
        },
        onShowHoverHighlight: (on) => _set(WidgetState.hovered, active: on),
        onFocusChange: (on) => _set(WidgetState.focused, active: on),
        onShowFocusHighlight: (on) => setState(() => _keyboardFocus = on),
        child: _gesture(context),
      ),
    );
  }

  Widget _gesture(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTapDown: (_) => _set(WidgetState.pressed, active: _enabled),
      onTapUp: (_) => _set(WidgetState.pressed, active: false),
      onTapCancel: () => _set(WidgetState.pressed, active: false),
      onTap: _activate,
      child: _touchTarget(context),
    );
  }

  /// O alvo tocável tem no mínimo 48 dp de lado, mesmo quando o desenho é
  /// menor — caso do chip, que tem 36 de altura (RNF-A11Y-05).
  Widget _touchTarget(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: CajuiSpacing.touchTarget,
        minHeight: CajuiSpacing.touchTarget,
      ),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: _spring(context),
      ),
    );
  }

  Widget _spring(BuildContext context) {
    final motion = CajuiTheme.of(context).motionLevel;
    final pressed = _states.contains(WidgetState.pressed);
    return AnimatedScale(
      scale: pressed && motion.allowsSpring ? 0.97 : 1,
      duration: pressed ? CajuiDurations.instant : CajuiDurations.fast,
      curve: CajuiCurves.spring,
      child: FocusRing(
        visible: _keyboardFocus && _enabled,
        radius: widget.radius,
        child: widget.builder(context, _visibleStates),
      ),
    );
  }

  static const _activationKeys = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
  };
}
