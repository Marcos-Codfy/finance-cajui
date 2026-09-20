/// Design system do Cajui: tokens, tema, componentes, movimento e som.
///
/// O app importa só esta biblioteca. Nada fora deste pacote define cor, tipo,
/// espaçamento ou duração — é o que garante que mudar a aparência de todos os
/// botões de ação seja editar um token, num lugar só.
///
/// A paleta crua (`CajuiPalette`) não é exportada de propósito: quem usa o
/// pacote pede um papel (`colors.action.primary`), nunca um tom.
library;

export 'src/accessibility/contrast_audit.dart';
export 'src/accessibility/contrast_pair.dart';
export 'src/accessibility/contrast_requirement.dart';
export 'src/accessibility/wcag_contrast.dart';
export 'src/motion/motion_level.dart';
export 'src/theme/cajui_theme.dart';
export 'src/theme/cajui_theme_data.dart';
export 'src/tokens/primitives/cajui_curves.dart';
export 'src/tokens/primitives/cajui_durations.dart';
export 'src/tokens/primitives/cajui_radius.dart';
export 'src/tokens/primitives/cajui_shadows.dart';
export 'src/tokens/primitives/cajui_spacing.dart';
export 'src/tokens/semantic/action_colors.dart';
export 'src/tokens/semantic/border_colors.dart';
export 'src/tokens/semantic/brand_colors.dart';
export 'src/tokens/semantic/cajui_colors.dart';
export 'src/tokens/semantic/data_colors.dart';
export 'src/tokens/semantic/intent_colors.dart';
export 'src/tokens/semantic/shortfall_style.dart';
export 'src/tokens/semantic/surface_colors.dart';
export 'src/tokens/semantic/text_colors.dart';
export 'src/typography/cajui_typography.dart';
