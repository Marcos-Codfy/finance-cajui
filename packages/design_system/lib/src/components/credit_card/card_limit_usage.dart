import 'package:design_system/src/format/brl_formatter.dart';
import 'package:design_system/src/tokens/semantic/cajui_colors.dart';
import 'package:flutter/widgets.dart';

/// Quanto do limite de um cartão está em uso, e como dizer isso.
///
/// O cartão é forma de pagamento, nunca despesa: aqui se fala em limite
/// "em uso" e "livre", nunca em "gasto". E os dois degraus — metade e 80% —
/// mudam o tom da barra e descrevem o fato, sem alarme: "Metade do limite
/// já está em uso", e não "cuidado".
@immutable
class CardLimitUsage {
  /// Calcula o uso de [usedCents] sobre o limite [limitCents].
  const new({required this.usedCents, required this.limitCents})
    : assert(limitCents > 0, 'Cartão sem limite não tem medidor.');

  /// O que já está em uso, em centavos.
  final int usedCents;

  /// O limite do cartão, em centavos.
  final int limitCents;

  /// A partir daqui o tom muda e a frase diz que metade está em uso.
  static const double half = 0.5;

  /// A partir daqui o tom é o da falta, e a frase diz que passou de 80%.
  static const double near = 0.8;

  /// A fração em uso. Passa de 1 quando o limite foi ultrapassado.
  double get fraction => usedCents / limitCents;

  /// O percentual em uso, arredondado: "62".
  int get percent => (fraction * 100).round();

  /// O que ainda está livre. Nunca negativo: quem passou do limite tem zero
  /// livre, e a frase conta quanto passou.
  int get freeCents => usedCents >= limitCents ? 0 : limitCents - usedCents;

  /// A frase que descreve o momento do limite.
  String get note {
    if (usedCents > limitCents) {
      return 'Passou ${BrlFormatter.format(usedCents - limitCents)} do limite';
    }
    if (fraction >= 1) return 'O limite inteiro está em uso';
    if (fraction >= near) return 'Mais de 80% do limite está em uso';
    if (fraction >= half) return 'Metade do limite já está em uso';
    return 'A maior parte do limite está livre';
  }

  /// A cor da barra: a da sobra até a metade, a do cajuí até 80% e, daí em
  /// diante, a da falta — barro ou vermelho, conforme a escolha do tema.
  Color fill(CajuiColors colors) {
    if (fraction >= near) return colors.shortfall;
    if (fraction >= half) return colors.data.variable;
    return colors.intent.positive;
  }

  /// Tudo em uma frase, para o leitor de tela.
  String get spoken =>
      'em uso ${BrlFormatter.format(usedCents)}, '
      'livre ${BrlFormatter.format(freeCents)}, $percent% do limite. $note';
}
