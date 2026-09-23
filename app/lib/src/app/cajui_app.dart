import 'package:cajui/src/app/home_shell.dart';
import 'package:cajui/src/core/appearance/appearance_controller.dart';
import 'package:cajui/src/core/feedback/feedback_providers.dart';
import 'package:cajui/src/features/ledger/presentation/sync_on_resume.dart';
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
      home: const SyncOnResume(child: HomeShell()),
    );
  }
}
