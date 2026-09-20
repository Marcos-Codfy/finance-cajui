import 'package:design_system/src/tokens/primitives/cajui_palette.dart';
import 'package:flutter/widgets.dart';

/// Cores de intenção: `intent.positive`, `intent.notice`, `intent.danger`…
///
/// Cada intenção tem a cor de frente e um fundo sutil. Cor nunca é o único
/// sinal: todo uso vem com rótulo e ícone (RN-671, WCAG 1.4.1).
///
/// `danger` é reservado a erro de sistema e ação destrutiva. Falta do mês,
/// dívida e limite ultrapassado **não** são perigo: usam `notice` (D-UX-02).
@immutable
class IntentColors {
  /// Cria o conjunto de cores de intenção de um tema.
  const new({
    required this.positive,
    required this.positiveSubtle,
    required this.notice,
    required this.noticeSubtle,
    required this.danger,
    required this.dangerSubtle,
    required this.info,
    required this.infoSubtle,
    required this.achievement,
    required this.achievementSubtle,
  });

  /// Sobra, progresso, confirmação.
  final Color positive;

  /// Fundo sutil de [positive].
  final Color positiveSubtle;

  /// Atenção sem alarme: falta, limite ultrapassado, parcela em aberto.
  final Color notice;

  /// Fundo sutil de [notice].
  final Color noticeSubtle;

  /// Erro de sistema e ação destrutiva. Nada além disso.
  final Color danger;

  /// Fundo sutil de [danger].
  final Color dangerSubtle;

  /// Informação neutra.
  final Color info;

  /// Fundo sutil de [info].
  final Color infoSubtle;

  /// Conquista, quando precisa ser lida como texto.
  final Color achievement;

  /// Fundo sutil de [achievement].
  final Color achievementSubtle;

  /// Intenções do tema claro.
  static const light = IntentColors(
    positive: CajuiPalette.vereda,
    positiveSubtle: CajuiPalette.veredaWash,
    notice: CajuiPalette.clay,
    noticeSubtle: CajuiPalette.clayWash,
    danger: CajuiPalette.red,
    dangerSubtle: CajuiPalette.redWash,
    info: CajuiPalette.sky,
    infoSubtle: CajuiPalette.skyWash,
    achievement: CajuiPalette.goldStrong,
    achievementSubtle: CajuiPalette.goldWash,
  );

  /// Intenções do tema escuro.
  static const dark = IntentColors(
    positive: CajuiPalette.veredaLight,
    positiveSubtle: CajuiPalette.veredaShade,
    notice: CajuiPalette.clayLight,
    noticeSubtle: CajuiPalette.clayShade,
    danger: CajuiPalette.redLight,
    dangerSubtle: CajuiPalette.redShade,
    info: CajuiPalette.skyLight,
    infoSubtle: CajuiPalette.skyShade,
    achievement: CajuiPalette.goldLight,
    achievementSubtle: CajuiPalette.goldShade,
  );
}
