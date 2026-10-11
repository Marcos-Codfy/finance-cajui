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
export 'src/app/cajui_app_surface.dart';
export 'src/app/cajui_localizations.dart';
export 'src/app/cajui_page_route.dart';
export 'src/components/amount/cajui_amount_text.dart';
export 'src/components/amount/cajui_amount_tone.dart';
export 'src/components/button/cajui_button.dart';
export 'src/components/button/cajui_button_size.dart';
export 'src/components/button/cajui_button_tokens.dart';
export 'src/components/button/cajui_button_variant.dart';
export 'src/components/button/cajui_icon_button.dart';
export 'src/components/card/cajui_card.dart';
export 'src/components/chat/cajui_chat_bubble.dart';
export 'src/components/chip/cajui_chip.dart';
export 'src/components/confidence/cajui_confidence_indicator.dart';
export 'src/components/confidence/cajui_confidence_level.dart';
export 'src/components/empty/cajui_empty_state.dart';
export 'src/components/feedback/cajui_loading_dots.dart';
export 'src/components/field/cajui_amount_field.dart';
export 'src/components/field/cajui_field_frame.dart';
export 'src/components/field/cajui_field_label.dart';
export 'src/components/field/cajui_option_list.dart';
export 'src/components/field/cajui_select_field.dart';
export 'src/components/field/cajui_text_field.dart';
export 'src/components/field/cents_input_formatter.dart';
export 'src/components/list/cajui_list_row.dart';
export 'src/components/meter/cajui_meter.dart';
export 'src/components/nav/cajui_nav_bar.dart';
export 'src/components/nav/cajui_nav_destination.dart';
export 'src/components/notice/cajui_notice.dart';
export 'src/components/notice/cajui_notice_action.dart';
export 'src/components/notice/cajui_notice_intent.dart';
export 'src/components/screen/cajui_screen.dart';
export 'src/components/screen/cajui_section_title.dart';
export 'src/components/skeleton/cajui_skeleton.dart';
export 'src/components/stat/cajui_stat_card.dart';
export 'src/components/switch/cajui_switch.dart';
export 'src/feedback/cajui_feedback.dart';
export 'src/feedback/cajui_feedback_scope.dart';
export 'src/feedback/silent_feedback.dart';
export 'src/format/brl_formatter.dart';
export 'src/icons/cajui_icon.dart';
export 'src/icons/cajui_icon_data.dart';
export 'src/illustrations/cajui_hero_fruit.dart';
export 'src/illustrations/hero_fruit_painter.dart';
export 'src/interaction/cajui_pressable.dart';
export 'src/interaction/focus_ring.dart';
export 'src/motion/cajui_count_up.dart';
export 'src/motion/cajui_entrance.dart';
export 'src/motion/frame_budget_monitor.dart';
export 'src/motion/frame_budget_window.dart';
export 'src/motion/motion_level.dart';
export 'src/motion/motion_level_resolver.dart';
export 'src/sound/audioplayers_sound_player.dart';
export 'src/sound/cajui_sound.dart';
export 'src/sound/sound_and_haptic_feedback.dart';
export 'src/sound/sound_category.dart';
export 'src/sound/sound_player.dart';
export 'src/sound/sound_settings.dart';
export 'src/theme/cajui_theme.dart';
export 'src/theme/cajui_theme_data.dart';
export 'src/tokens/primitives/cajui_curves.dart';
export 'src/tokens/primitives/cajui_durations.dart';
export 'src/tokens/primitives/cajui_radius.dart';
export 'src/tokens/primitives/cajui_shadows.dart';
export 'src/tokens/primitives/cajui_spacing.dart';
export 'src/tokens/primitives/cajui_springs.dart';
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
