import 'package:cajui/src/core/appearance/appearance_controller.dart';
import 'package:cajui/src/core/feedback/sound_settings_controller.dart';
import 'package:cajui/src/features/auth/presentation/household_key_page.dart';
import 'package:cajui/src/features/budget/presentation/plan_page.dart';
import 'package:cajui/src/features/cards/presentation/cards_page.dart';
import 'package:cajui/src/features/debts/presentation/debts_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O que a pessoa regula no app: o plano do mês, os cartões, as dívidas, o
/// fechamento, a chave da casa e o retorno sensorial.
///
/// Nada de servidor: o celular sincroniza sozinho (ADR-020), e o que havia
/// aqui para mandar e para cadastrar aparelho deixou de existir.
class SettingsPage extends ConsumerWidget {
  /// Cria a tela de ajustes.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CajuiScreen(
      title: 'Ajustes',
      children: [
        ..._cadastros(context),
        ..._appearance(ref),
        ..._feedback(ref),
      ],
    );
  }

  /// O que a pessoa cadastra uma vez e revisita de vez em quando.
  List<Widget> _cadastros(BuildContext context) => [
    _opens(
      title: 'Plano do mês',
      subtitle: 'Renda, contas fixas, gastos variáveis e dívidas',
      onPressed: () => PlanPage.open(context),
    ),
    _opens(
      title: 'Cartões de crédito',
      subtitle: 'Por onde se paga — e a fatura de cada um',
      onPressed: () => CardsPage.open(context),
    ),
    _opens(
      title: 'Dívidas',
      subtitle: 'Quanto falta de cada uma, e quando termina',
      onPressed: () => DebtsPage.open(context),
    ),
    _opens(
      title: 'Chave da casa',
      subtitle: 'Para entrar na consulta pela web de outro computador',
      onPressed: () => HouseholdKeyPage.open(context),
    ),
  ];

  Widget _opens({
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) => CajuiListRow(
    title: title,
    subtitle: subtitle,
    trailing: const CajuiIcon(CajuiIconData.chevronRight),
    semanticLabel: '$title, abrir',
    onPressed: onPressed,
  );

  /// O tema: o app nasce claro, e o escuro é escolha de quem usa.
  List<Widget> _appearance(WidgetRef ref) => [
    CajuiListRow(
      title: 'Tema escuro',
      subtitle: 'O app abre no claro; o escuro fica se você ligar',
      trailing: CajuiSwitch(
        value: ref.watch(appearanceProvider),
        semanticLabel: 'Tema escuro',
        onChanged: (enabled) =>
            ref.read(appearanceProvider.notifier).setDark(enabled: enabled),
      ),
    ),
  ];

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
