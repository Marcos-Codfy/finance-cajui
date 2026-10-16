import 'dart:async';

import 'package:design_system/src/components/feedback/cajui_loading_dots.dart';
import 'package:design_system/src/feedback/cajui_feedback_scope.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// Puxar a tela para baixo, do topo, para atualizar (pedido do dono em
/// 16/10/2026: "forçar a atualização quando eu estiver no topo da tela").
///
/// O app não usa o Material, e o `RefreshIndicator` é dele: este ouve a
/// rolagem da lista que estiver dentro — a física que for, a que estica
/// (iOS) ou a que trava no topo (Android) — e mede o quanto passou do
/// topo. Passou de [trigger] e soltou, roda [onRefresh]; enquanto roda, os
/// três pontos ficam no alto e um segundo puxão não repete o pedido.
class CajuiPullToRefresh extends StatefulWidget {
  /// Envolve [child], que deve ter uma lista rolável.
  const new({required this.onRefresh, required this.child, super.key});

  /// O que atualizar. A tela não espera por mais que isto.
  final Future<void> Function() onRefresh;

  /// A tela com a lista.
  final Widget child;

  /// Quanto puxar para valer: uma unha a mais que um toque comprido.
  static const double trigger = 72;

  @override
  State<CajuiPullToRefresh> createState() => _CajuiPullToRefreshState();
}

class _CajuiPullToRefreshState extends State<CajuiPullToRefresh> {
  double _pulled = 0;
  bool _running = false;
  bool _armed = false;

  bool _heard(ScrollNotification note) {
    if (note.depth != 0 || _running) return false;
    switch (note) {
      case OverscrollNotification(:final overscroll, :final dragDetails)
          when dragDetails != null && overscroll < 0:
        _pull(_pulled - overscroll);
      case ScrollUpdateNotification(:final metrics, :final dragDetails)
          when dragDetails != null:
        // A física que estica deixa a posição passar do topo; a que trava
        // avisa por `OverscrollNotification`. Descer a lista desarma.
        final above = metrics.minScrollExtent - metrics.pixels;
        _pull(above > 0 ? above : (_pulled > 0 ? 0 : _pulled));
      case ScrollEndNotification():
        _release();
    }
    return false;
  }

  void _pull(double value) {
    final armed = value >= CajuiPullToRefresh.trigger;
    if (armed && !_armed) CajuiFeedbackScope.of(context).toggle(on: true);
    setState(() {
      _pulled = value;
      _armed = armed;
    });
  }

  void _release() {
    final go = _armed;
    setState(() {
      _pulled = 0;
      _armed = false;
    });
    if (go) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    setState(() => _running = true);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_pulled / CajuiPullToRefresh.trigger).clamp(0.0, 1.0);
    final shown = _running ? 1.0 : progress;
    return NotificationListener<ScrollNotification>(
      onNotification: _heard,
      child: Stack(
        children: [
          widget.child,
          Positioned(
            top: MediaQuery.paddingOf(context).top + CajuiSpacing.sm,
            left: 0,
            right: 0,
            child: IgnorePointer(child: _signal(context, shown)),
          ),
        ],
      ),
    );
  }

  /// Os três pontos: aparecem com o puxão e ficam enquanto atualiza.
  Widget _signal(BuildContext context, double shown) {
    if (shown == 0) return const SizedBox.shrink();
    final colors = CajuiTheme.of(context).colors;
    return Semantics(
      liveRegion: true,
      label: _running ? 'Atualizando' : null,
      child: Opacity(
        opacity: shown,
        child: Center(
          child: CajuiLoadingDots(
            color: _armed || _running
                ? colors.action.primary
                : colors.text.muted,
          ),
        ),
      ),
    );
  }
}
