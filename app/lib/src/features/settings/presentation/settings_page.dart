import 'package:cajui/src/core/feedback/sound_settings_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O que a pessoa regula no app. Por ora, o retorno sensorial.
class SettingsPage extends ConsumerWidget {
  /// Cria a tela de ajustes.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(soundSettingsProvider);
    final controller = ref.read(soundSettingsProvider.notifier);
    return CajuiScreen(
      title: 'Ajustes',
      children: [
        CajuiListRow(
          title: 'Sons',
          subtitle: 'Toques suaves ao tocar, salvar e confirmar',
          trailing: CajuiSwitch(
            value: settings.soundEnabled,
            semanticLabel: 'Sons',
            onChanged: (enabled) => controller.setSound(enabled: enabled),
          ),
        ),
        CajuiListRow(
          title: 'Vibração',
          subtitle: 'Um toque leve junto de cada ação',
          trailing: CajuiSwitch(
            value: settings.hapticsEnabled,
            semanticLabel: 'Vibração',
            onChanged: (enabled) => controller.setHaptics(enabled: enabled),
          ),
        ),
      ],
    );
  }
}
