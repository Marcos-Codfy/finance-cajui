import 'package:cajui/src/app/home_shell.dart';
import 'package:cajui/src/core/feedback/feedback_providers.dart';
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
      pageRouteBuilder: <T>(settings, builder) =>
          CajuiPageRoute<T>(settings: settings, builder: builder),
      builder: (context, child) => CajuiAppSurface(
        theme: CajuiAppSurface.themeOf(context),
        feedback: ref.watch(feedbackProvider),
        child: child!,
      ),
      home: const HomeShell(),
    );
  }
}
