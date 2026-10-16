import 'dart:async';

import 'package:cajui/src/features/cards/presentation/cards_page.dart';
import 'package:cajui/src/features/home/application/setup_steps.dart';
import 'package:cajui/src/features/home_widget/application/home_widget_providers.dart';
import 'package:cajui/src/features/settings/presentation/household_names_page.dart';
import 'package:cajui/src/features/settings/presentation/settings_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Primeiros passos": o que falta configurar, cada linha levando ao lugar.
/// Some quando não falta nada — não é aviso, é atalho.
class HomeSetupCard extends ConsumerWidget {
  /// Cria o cartão.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(setupStepsProvider).value ?? const [];
    if (steps.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.xl),
      child: CajuiCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CajuiSectionTitle('Primeiros passos'),
            for (final step in steps) _row(context, ref, step),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, SetupStep step) {
    final (title, subtitle, icon) = _texts(step);
    return CajuiListRow(
      title: title,
      subtitle: subtitle,
      leading: CajuiIcon(icon),
      trailing: const CajuiIcon(CajuiIconData.chevronRight),
      semanticLabel: title,
      onPressed: () => unawaited(_go(context, ref, step)),
    );
  }

  static (String, String, CajuiIconData) _texts(SetupStep step) =>
      switch (step) {
        SetupStep.names => (
          'Cadastre os nomes da casa',
          'Para o Pix entre vocês não contar como gasto',
          CajuiIconData.wallet,
        ),
        SetupStep.notifications => (
          'Lance pelas notificações do banco',
          'O Cajui lê o aviso do banco e lança sozinho',
          CajuiIconData.receipt,
        ),
        SetupStep.widget => (
          'Ponha o Cajui na tela inicial',
          'A sobra do mês à vista, sem abrir o app',
          CajuiIconData.chart,
        ),
        SetupStep.cardLimits => (
          'Informe o limite dos cartões',
          'Para ver quanto do limite já foi usado',
          CajuiIconData.card,
        ),
      };

  /// Leva ao lugar e, na volta, confere de novo o que falta.
  static Future<void> _go(
    BuildContext context,
    WidgetRef ref,
    SetupStep step,
  ) async {
    await switch (step) {
      SetupStep.names => HouseholdNamesPage.open(context),
      SetupStep.notifications => SettingsPage.open(context),
      SetupStep.widget => ref.read(homeScreenProvider).pin(),
      SetupStep.cardLimits => CardsPage.open(context),
    };
    ref.invalidate(setupStepsProvider);
  }
}
