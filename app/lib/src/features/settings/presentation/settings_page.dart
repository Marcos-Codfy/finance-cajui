import 'package:cajui/src/core/appearance/appearance_controller.dart';
import 'package:cajui/src/core/feedback/sound_settings_controller.dart';
import 'package:cajui/src/features/auth/application/household_key_store.dart';
import 'package:cajui/src/features/auth/presentation/household_key_page.dart';
import 'package:cajui/src/features/home_widget/presentation/home_widget_row.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:cajui/src/features/notifications/presentation/bank_notifications_row.dart';
import 'package:cajui/src/features/reminders/presentation/due_reminders_row.dart';
import 'package:cajui/src/features/settings/presentation/household_names_row.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O que a pessoa regula no app: a chave da casa, as notificações do banco,
/// o tema e o retorno sensorial. O plano, os cartões e as dívidas moram no Início, junto do
/// mês, como na planilha.
///
/// Nada de servidor: o celular sincroniza sozinho (ADR-020), e o que havia
/// aqui para mandar e para cadastrar aparelho deixou de existir.
class SettingsPage extends ConsumerWidget {
  /// Cria a tela de ajustes.
  const new({super.key});

  /// Abre a tela, a partir do Início.
  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push<void>(CajuiPageRoute(builder: (_) => const SettingsPage()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CajuiScreen(
      title: 'Ajustes',
      onBack: Navigator.of(context).maybePop,
      // A rolagem em profundidade e a entrada de câmera (ADR-028).
      depth: true,
      cinematic: true,
      children: [
        ..._cadastros(context, ref),
        const BankNotificationsRow(),
        const HouseholdNamesRow(),
        const DueRemindersRow(),
        const HomeWidgetRow(),
        ..._appearance(ref),
        ..._feedback(ref),
      ],
    );
  }

  /// O que a pessoa cadastra uma vez e revisita de vez em quando. A chave
  /// da casa aparece só no celular: na consulta, o que o navegador guarda
  /// pode ser a sessão do código (ADR-027), e mostrá-la como "a chave"
  /// ensinaria a copiar um token que só lê e vence em trinta dias. No lugar
  /// dela, a consulta tem o "Sair" que a tela de entrada promete.
  List<Widget> _cadastros(BuildContext context, WidgetRef ref) => [
    if (ref.watch(ledgerUplinkProvider).isPaired)
      _opens(
        title: 'Chave da casa',
        subtitle: 'Para entrar na consulta pela web de outro computador',
        onPressed: () => HouseholdKeyPage.open(context),
      )
    else
      CajuiListRow(
        title: 'Sair',
        subtitle:
            'Este navegador esquece a entrada; para voltar, o código '
            'do autenticador',
        semanticLabel: 'Sair deste navegador',
        onPressed: () => _signOut(context, ref),
      ),
  ];

  /// Volta ao começo e esquece a entrada: a tela de entrada toma o lugar da
  /// casca, e Ajustes não pode ficar empilhado por cima dela. A porta da
  /// chave é lida antes de a tela sair, porque depois o `ref` já não vale.
  static Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final keys = ref.read(householdKeyProvider);
    Navigator.of(context).popUntil((route) => route.isFirst);
    await keys.forget();
  }

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
