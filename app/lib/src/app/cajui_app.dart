import 'package:cajui/src/app/home_shell.dart';
import 'package:cajui/src/core/appearance/appearance_controller.dart';
import 'package:cajui/src/core/feedback/feedback_providers.dart';
import 'package:cajui/src/features/auth/application/household_key_presence.dart';
import 'package:cajui/src/features/auth/presentation/key_page.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:cajui/src/features/ledger/presentation/sync_on_resume.dart';
import 'package:cajui/src/features/notifications/presentation/notifications_host.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A raiz do app: liga o tema do aparelho, o retorno sensorial e a navegação.
///
/// É um `WidgetsApp`, e não um `MaterialApp`: toda a aparência vem do design
/// system, e não há tema de terceiros por baixo para vazar na tela.
class CajuiApp extends ConsumerWidget {
  /// Cria o app.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WidgetsApp(
      title: 'Cajui',
      // A cor que o Android mostra na lista de apps recentes.
      color: CajuiThemeData.light().colors.surface.base,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: CajuiLocalizations.delegates,
      // Um idioma só, e sempre ele: o app não muda de língua com o aparelho.
      supportedLocales: CajuiLocalizations.locales,
      locale: CajuiLocalizations.locales.first,
      pageRouteBuilder: <T>(settings, builder) =>
          CajuiPageRoute<T>(settings: settings, builder: builder),
      builder: (context, child) => CajuiAppSurface(
        // A escolha de quem usa vence o aparelho: o app nasce claro.
        theme: CajuiAppSurface.themeOf(
          context,
          dark: ref.watch(appearanceProvider),
        ),
        feedback: ref.watch(feedbackProvider),
        child: child!,
      ),
      home: _home(ref),
    );
  }

  /// A consulta na web sem a chave da casa mostra só a entrada: o livro
  /// dela é o do servidor, e sem chave não há livro (ADR-020). No celular a
  /// chave vem no APK, e a casca abre direto.
  static Widget _home(WidgetRef ref) {
    final consulta = !ref.watch(ledgerUplinkProvider).isPaired;
    if (consulta && !ref.watch(hasHouseholdKeyProvider)) return const KeyPage();
    return const SyncOnResume(child: NotificationsHost(child: HomeShell()));
  }
}
