import 'package:design_system/src/motion/motion_level.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:flutter/widgets.dart';

/// O nível de movimento que vale para [context]: o do tema, rebaixado a
/// `reduced` quando o sistema pede menos movimento.
///
/// O `CajuiAppSurface.themeOf` já faz essa conta para o app. Os efeitos de
/// profundidade a refazem porque são os que mais mexem com o olho: se alguém
/// montar o tema à mão — a gallery, um teste, outro app —, o pedido do
/// sistema continua valendo (RNF-A11Y-07).
MotionLevel motionOf(BuildContext context) {
  final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  if (reduce) return MotionLevel.reduced;
  return CajuiTheme.of(context).motionLevel;
}
