import 'package:design_system/src/tokens/semantic/cajui_colors.dart';
import 'package:flutter/widgets.dart';

/// O que um valor está dizendo, e portanto com que cor ele aparece.
///
/// A cor é reforço, nunca o único sinal: sobra e falta vêm sempre com o
/// rótulo em texto ("sobram", "faltam") ao lado do número (RN-671).
enum CajuiAmountTone {
  /// Um valor qualquer: cor do texto principal.
  neutral,

  /// Valor de apoio, em segundo plano.
  muted,

  /// Sobra, folga, o que ainda cabe.
  positive,

  /// Falta, o que passou do limite, o que está em aberto. Usa a cor escolhida
  /// para a falta do mês — barro ou vermelho —, num lugar só.
  shortfall,

  /// O valor em destaque da tela: a cor de ação.
  accent;

  /// A cor deste tom no tema em vigor.
  Color resolve(CajuiColors colors) => switch (this) {
    CajuiAmountTone.neutral => colors.text.primary,
    CajuiAmountTone.muted => colors.text.muted,
    CajuiAmountTone.positive => colors.intent.positive,
    CajuiAmountTone.shortfall => colors.shortfall,
    CajuiAmountTone.accent => colors.action.primary,
  };
}
