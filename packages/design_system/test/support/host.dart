import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Monta o que um componente precisa para viver num teste: um app de verdade
/// — com direção de texto e os atalhos de teclado padrão, inclusive o Tab —,
/// o tema e, se pedido, uma resposta sonora para espiar.
Widget host(
  Widget child, {
  CajuiThemeData? theme,
  CajuiFeedback feedback = const SilentFeedback(),
}) {
  return WidgetsApp(
    color: const Color(0xFFFBF6EE),
    debugShowCheckedModeBanner: false,
    builder: (context, _) => CajuiTheme(
      data: theme ?? CajuiThemeData.light(),
      child: CajuiFeedbackScope(
        feedback: feedback,
        // Num app, quem dá o foco inicial é o navegador de rotas. Aqui não há
        // rotas, então o escopo pede o foco para o Tab ter de onde partir.
        child: FocusScope(autofocus: true, child: Center(child: child)),
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
}
