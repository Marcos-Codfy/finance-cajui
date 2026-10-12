import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/app/gallery_scope.dart';

/// Os três níveis de movimento, ao alcance de cada página de profundidade:
/// conferir a versão parada não pode exigir ir até a mesa de movimento.
class MotionLevelChips extends StatelessWidget {
  /// Cria os chips; [action], se dado, vai ao lado deles.
  const new({this.action, super.key});

  /// Um botão ao lado, como "Rodar de novo".
  final Widget? action;

  static const Map<MotionLevel, String> _levels = {
    MotionLevel.full: 'Completo',
    MotionLevel.lite: 'Leve',
    MotionLevel.reduced: 'Reduzido',
  };

  /// O botão de repetir fica numa linha própria, embaixo: colado aos chips,
  /// ele parecia um quarto nível — duas pílulas vermelhas lado a lado, uma
  /// escolha e uma ação.
  @override
  Widget build(BuildContext context) {
    final controller = GalleryScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: CajuiSpacing.md,
      children: [
        Wrap(
          spacing: CajuiSpacing.sm,
          runSpacing: CajuiSpacing.sm,
          children: [
            for (final MapEntry(key: level, value: label) in _levels.entries)
              CajuiChip(
                label: label,
                selected: controller.motionLevel == level,
                onSelected: (_) => controller.useMotionLevel(level),
              ),
          ],
        ),
        ?action,
      ],
    );
  }
}
