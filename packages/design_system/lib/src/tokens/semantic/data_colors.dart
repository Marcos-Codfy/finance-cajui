import 'package:design_system/src/tokens/primitives/cajui_palette.dart';
import 'package:flutter/widgets.dart';

/// Cores dos segmentos de gráfico: `data.fixed`, `data.variable`…
///
/// Só existe gráfico onde há parte-todo ou progresso (RN-862). Os segmentos
/// são sempre separados por uma fresta na cor da superfície, então não
/// precisam de contraste entre si — só contra o fundo, o que o teste confere.
/// O vale tem cor própria porque nunca divide a mesma barra com dinheiro.
@immutable
class DataColors {
  /// Cria o conjunto de cores de dados de um tema.
  const new({
    required this.fixed,
    required this.variable,
    required this.debt,
    required this.subscription,
    required this.voucher,
    required this.track,
  });

  /// Bloco de fixos.
  final Color fixed;

  /// Bloco de variáveis.
  final Color variable;

  /// Bloco de dívidas.
  final Color debt;

  /// As assinaturas: o que se repete todo mês, de serviço.
  final Color subscription;

  /// Vale alimentação, sempre em barra separada.
  final Color voucher;

  /// O trilho vazio de uma barra ou medidor.
  final Color track;

  /// Dados no tema claro.
  static const light = DataColors(
    fixed: CajuiPalette.inkSoft,
    variable: CajuiPalette.cajui,
    debt: CajuiPalette.clay,
    subscription: CajuiPalette.ipe,
    voucher: CajuiPalette.vereda,
    // Areia funda, e não o tom mais escuro: só com ela o cajuí do medidor
    // chega a 3:1 contra o trilho (3,09:1; com sandMuted dava 2,79:1).
    track: CajuiPalette.sandDeep,
  );

  /// Dados no tema escuro.
  static const dark = DataColors(
    fixed: CajuiPalette.moonSoft,
    variable: CajuiPalette.cajuiLight,
    debt: CajuiPalette.clayLight,
    subscription: CajuiPalette.ipeLight,
    voucher: CajuiPalette.veredaLight,
    track: CajuiPalette.nightHigh,
  );
}
