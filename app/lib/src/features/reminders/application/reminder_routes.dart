import 'package:domain/domain.dart';

/// O pedido de abertura que cada lembrete leva até o lado nativo e traz de
/// volta quando é tocado (RN-849, RN-1087).
///
/// É o contrato entre quem marca e quem abre: o texto atravessa o Android e
/// volta igual, e um assunto sem rota aqui seria um lembrete que abre o
/// painel genérico.
abstract final class ReminderRoutes {
  static const _prefix = 'reminder:';

  /// O pedido que abre a tela de [target].
  static String of(ReminderTarget target) => '$_prefix${target.name}';

  /// O assunto de [route], se ele é de um lembrete; nulo se é outro pedido.
  static ReminderTarget? targetOf(String route) {
    if (!route.startsWith(_prefix)) return null;
    final name = route.substring(_prefix.length);
    return ReminderTarget.values.where((t) => t.name == name).firstOrNull;
  }
}
