import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart' show DefaultMaterialLocalizations;
import 'package:flutter/widgets.dart';

/// Monta o que um componente precisa para viver num teste: um app de verdade,
/// com navegador de rotas — que dá o foco inicial para o Tab, a camada de
/// sobreposição que o campo de texto usa e os atalhos de teclado padrão —, o
/// tema e, se pedido, uma resposta sonora para espiar.
Widget host(
  Widget child, {
  CajuiThemeData? theme,
  CajuiFeedback feedback = const SilentFeedback(),
}) {
  return WidgetsApp(
    color: const Color(0xFFFBF6EE),
    debugShowCheckedModeBanner: false,
    // O campo de texto usa o do Material por dentro, que pede estes textos.
    localizationsDelegates: const [
      DefaultMaterialLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
    ],
    pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, _, _) => builder(context),
    ),
    home: CajuiTheme(
      data: theme ?? CajuiThemeData.light(),
      child: CajuiFeedbackScope(
        feedback: feedback,
        child: Center(child: child),
      ),
    ),
  );
}

/// Resposta que só anota o que foi pedido, para o teste conferir.
class RecordingFeedback implements CajuiFeedback {
  /// O que foi pedido, na ordem.
  final List<String> calls = [];

  @override
  void tap() => calls.add('tap');

  @override
  void toggle({required bool on}) => calls.add('toggle:$on');

  @override
  void open() => calls.add('open');

  @override
  void saved() => calls.add('saved');

  @override
  void notice() => calls.add('notice');

  @override
  void achievement() => calls.add('achievement');

  @override
  void entrySaved() => calls.add('entrySaved');

  @override
  void undone() => calls.add('undone');
}
