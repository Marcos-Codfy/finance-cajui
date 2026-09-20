import 'package:design_system/src/icons/cajui_icon_data.dart';
import 'package:design_system/src/tokens/semantic/cajui_colors.dart';
import 'package:flutter/widgets.dart';

/// O que um aviso está dizendo.
///
/// Repare no que **não** é perigo: falta do mês, limite ultrapassado, IA fora
/// do ar e comprovante ilegível são [attention]. [danger] fica para erro de
/// sistema que ameaça dado — banco corrompido — e para ação destrutiva.
enum CajuiNoticeIntent {
  /// Informação neutra: "sem conexão agora, o lançamento sobe depois".
  info(CajuiIconData.info),

  /// Algo deu certo e vale registrar.
  positive(CajuiIconData.check),

  /// Pede atenção, sem alarme. É o tom da maioria dos erros do app.
  attention(CajuiIconData.info),

  /// Erro de sistema que ameaça dado, ou ação sem volta.
  danger(CajuiIconData.info);

  new(this.icon);

  /// O ícone que acompanha o aviso. Nunca é só a cor que diz a intenção.
  final CajuiIconData icon;

  /// A cor de frente: ícone e título.
  Color foreground(CajuiColors c) => switch (this) {
    CajuiNoticeIntent.info => c.intent.info,
    CajuiNoticeIntent.positive => c.intent.positive,
    CajuiNoticeIntent.attention => c.intent.notice,
    CajuiNoticeIntent.danger => c.intent.danger,
  };

  /// O fundo sutil.
  Color background(CajuiColors c) => switch (this) {
    CajuiNoticeIntent.info => c.intent.infoSubtle,
    CajuiNoticeIntent.positive => c.intent.positiveSubtle,
    CajuiNoticeIntent.attention => c.intent.noticeSubtle,
    CajuiNoticeIntent.danger => c.intent.dangerSubtle,
  };
}
