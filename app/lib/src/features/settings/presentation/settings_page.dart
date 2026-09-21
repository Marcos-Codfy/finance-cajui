import 'package:cajui/src/core/feedback/sound_settings_controller.dart';
import 'package:cajui/src/features/budget/presentation/plan_page.dart';
import 'package:cajui/src/features/cards/presentation/cards_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O que a pessoa regula no app: o plano do mês e o retorno sensorial.
class SettingsPage extends ConsumerWidget {
  /// Cria a tela de ajustes.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CajuiScreen(
      title: 'Ajustes',
      children: [
        CajuiListRow(
          title: 'Plano do mês',
          subtitle: 'Renda, contas fixas, gastos variáveis e dívidas',
          trailing: const CajuiIcon(CajuiIconData.chevronRight),
          semanticLabel: 'Plano do mês, abrir',
          onPressed: () => PlanPage.open(context),
        ),
        CajuiListRow(
          title: 'Cartões de crédito',
          subtitle: 'Por onde se paga — e a fatura de cada um',
          trailing: const CajuiIcon(CajuiIconData.chevronRight),
          semanticLabel: 'Cartões de crédito, abrir',
          onPressed: () => CardsPage.open(context),
        ),
        ..._feedback(ref),
      ],
    );
  }

  /// Som e vibração: valem na hora, sem botão de salvar.
  List<Widget> _feedback(WidgetRef ref) {
    final settings = ref.watch(soundSettingsProvider);
    final controller = ref.read(soundSettingsProvider.notifier);
    return [
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
    ];
  }
}
