import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:design_system/src/motion/space_pose.dart';
import 'package:design_system/src/tokens/primitives/cajui_curves.dart';
import 'package:flutter/widgets.dart';

/// Onde um cartão da pilha de carteira está, e por quê: o lugar dele na
/// coluna, o quanto já saiu do maço e onde está a borda de cima da tela.
typedef WalletSlot = ({
  int index,
  int count,
  double top,
  double height,
  double lastTop,
  double gap,
});

/// A conta da pilha de carteira: três movimentos somados numa pose só.
///
/// - **O maço se abre.** Ao aparecer, os cartões estão empilhados no lugar
///   do primeiro, cada um um pouco menor e mais alto que o da frente; o da
///   frente sai primeiro e desce até o último lugar, e assim por diante —
///   como quem distribui cartas.
/// - **A pilha se refaz no alto.** Rolando para baixo, cada cartão que chega
///   à borda de cima para ali, e o seguinte o cobre; os de trás recuam e
///   aparecem só pela beirada. É a carteira que se fecha conforme se rola.
/// - **O leque.** Puxando além do topo, os cartões se afastam uns dos
///   outros, cada um mais que o de cima.
abstract final class WalletPose {
  /// A beirada de cada cartão de trás que fica à mostra acima do da frente.
  static const double _peek = 8;

  /// O quanto cada cartão de trás é menor que o da frente, no maço.
  static const double _deckShrink = 0.05;

  /// O quanto um cartão em voo se deita, no meio do caminho: uns 9°.
  static const double _flightTilt = 0.16;

  /// A fração do puxão além do topo que separa um cartão do seguinte.
  static const double _fan = 0.25;

  /// A pose do cartão em [slot]. [deal] é o quanto ele já saiu do maço; o
  /// alto da tela está em [viewportTop], nas coordenadas da pilha — `null`
  /// fora de uma rolagem vertical —; [pull] é o puxão além do topo. Com
  /// [fades], os cartões de trás escurecem um pouco.
  static SpacePose of(
    WalletSlot slot, {
    required double deal,
    double? viewportTop,
    double pull = 0,
    bool fades = true,
  }) {
    final dealt = CajuiCurves.settle.transform(deal.clamp(0.0, 1.0));
    final behind = slot.count - 1 - slot.index;
    final deckShift = -slot.top - behind * _peek;
    final stick = _stick(slot, viewportTop);
    final recede = (stick / (slot.height + slot.gap)).clamp(0.0, 3.0);
    return SpacePose(
      tilt: _flight(deal) * _flightTilt,
      scale:
          lerpDouble(1 - _deckShrink * behind, 1, dealt)! *
          (1 - 0.045 * recede),
      shift: Offset(
        0,
        deckShift * (1 - dealt) +
            stick -
            recede * _peek +
            slot.index * pull * _fan,
      ),
      opacity: fades ? 1 - 0.15 * recede : 1,
      pivot: Alignment.topCenter,
    );
  }

  /// O quanto o cartão está no meio do voo, de 0 a 1. Nas pontas, zero
  /// exato: o seno de π em ponto flutuante não é zero, e um resto de giro
  /// manteria uma camada viva no cartão parado.
  static double _flight(double deal) =>
      deal <= 0 || deal >= 1 ? 0 : math.sin(deal * math.pi);

  /// O quanto o cartão desce para ficar parado na borda de cima: até o
  /// último cartão chegar lá, quando a pilha inteira vai embora junta.
  static double _stick(WalletSlot slot, double? viewportTop) {
    if (viewportTop == null) return 0;
    final room = math.max<double>(0, slot.lastTop - slot.top);
    return (viewportTop - slot.top).clamp(0.0, room);
  }
}
