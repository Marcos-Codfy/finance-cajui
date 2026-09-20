import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/app/gallery_scope.dart';

/// Os controles que valem para a gallery inteira: tema escuro e som.
///
/// São chips, e não ícones soltos, porque o estado precisa estar escrito: cor
/// nunca é o único sinal.
class GalleryToolbar extends StatelessWidget {
  /// Cria a barra de controles.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GalleryScope.of(context);
    final sound = controller.sound;
    return Wrap(
      spacing: CajuiSpacing.sm,
      runSpacing: CajuiSpacing.sm,
      children: [
        CajuiChip(
          label: 'Tema escuro',
          selected: controller.brightness == Brightness.dark,
          onSelected: (_) => controller.toggleBrightness(),
        ),
        CajuiChip(
          label: 'Som',
          selected: sound.soundEnabled,
          onSelected: (on) =>
              controller.useSound(sound.copyWith(soundEnabled: on)),
        ),
      ],
    );
  }
}
