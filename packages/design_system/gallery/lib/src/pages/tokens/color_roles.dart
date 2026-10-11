import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Um grupo de papéis de cor, com o nome que aparece na página.
typedef ColorRoleGroup = ({
  String title,
  String note,
  Map<String, Color> roles,
});

/// Lista os papéis de cor de um tema pelo nome que o código usa.
///
/// A página de cores mostra papéis, nunca tons: é o mesmo contrato do pacote,
/// que não exporta a paleta crua.
abstract final class ColorRoles {
  /// Os grupos de papéis de [c], na ordem da página.
  static List<ColorRoleGroup> groupsOf(CajuiColors c) => [
    _surface(c),
    _text(c),
    _action(c),
    _intent(c),
    _border(c),
    _brandAndData(c),
    _shortfall(c),
  ];

  static ColorRoleGroup _surface(CajuiColors c) => (
    title: 'Superfície',
    note: 'Os planos da tela, do fundo ao que flutua por cima.',
    roles: {
      'surface.base': c.surface.base,
      'surface.sunken': c.surface.sunken,
      'surface.elevated': c.surface.elevated,
      'surface.high': c.surface.high,
      'surface.scrim': c.surface.scrim,
    },
  );

  static ColorRoleGroup _text(CajuiColors c) => (
    title: 'Texto',
    note: 'Três pesos de leitura, mais o texto sobre ação, o link e o inativo.',
    roles: {
      'text.primary': c.text.primary,
      'text.muted': c.text.muted,
      'text.faint': c.text.faint,
      'text.onAction': c.text.onAction,
      'text.link': c.text.link,
      'text.disabled': c.text.disabled,
    },
  );

  static ColorRoleGroup _action(CajuiColors c) => (
    title: 'Ação',
    note:
        'Mudar `action.primary` muda todos os botões principais do app, '
        'num lugar só.',
    roles: {
      'action.primary': c.action.primary,
      'action.primaryHover': c.action.primaryHover,
      'action.primaryPressed': c.action.primaryPressed,
      'action.secondary': c.action.secondary,
      'action.secondaryHover': c.action.secondaryHover,
      'action.secondaryPressed': c.action.secondaryPressed,
      'action.disabled': c.action.disabled,
    },
  );

  static ColorRoleGroup _intent(CajuiColors c) => (
    title: 'Intenção',
    note: 'Cada intenção tem a cor cheia e o fundo suave do aviso.',
    roles: {
      'intent.positive': c.intent.positive,
      'intent.positiveSubtle': c.intent.positiveSubtle,
      'intent.notice': c.intent.notice,
      'intent.noticeSubtle': c.intent.noticeSubtle,
      'intent.danger': c.intent.danger,
      'intent.dangerSubtle': c.intent.dangerSubtle,
      'intent.info': c.intent.info,
      'intent.infoSubtle': c.intent.infoSubtle,
      'intent.achievement': c.intent.achievement,
      'intent.achievementSubtle': c.intent.achievementSubtle,
    },
  );

  static ColorRoleGroup _border(CajuiColors c) => (
    title: 'Borda e foco',
    note: 'O anel de foco tem cor própria e uma folga que o separa do fundo.',
    roles: {
      'border.subtle': c.border.subtle,
      'border.field': c.border.field,
      'border.strong': c.border.strong,
      'border.focusRing': c.border.focusRing,
      'border.focusGap': c.border.focusGap,
    },
  );

  static ColorRoleGroup _brandAndData(CajuiColors c) => (
    title: 'Marca e dados',
    note:
        'As cores dos três blocos de despesa e do vale, nos gráficos; a água '
        'do pote; e a luz que bate no cartão em 3D.',
    roles: {
      'brand.accent': c.brand.accent,
      'brand.gold': c.brand.gold,
      'data.fixed': c.data.fixed,
      'data.variable': c.data.variable,
      'data.debt': c.data.debt,
      'data.voucher': c.data.voucher,
      'data.track': c.data.track,
      'brand.sheen': c.brand.sheen,
    },
  );

  static ColorRoleGroup _shortfall(CajuiColors c) => (
    title: 'Falta do mês',
    note:
        'Um papel só, com duas versões em avaliação. O componente pede '
        '`colors.shortfall` e não sabe qual está em vigor.',
    roles: {'shortfall': c.shortfall, 'shortfallSubtle': c.shortfallSubtle},
  );
}
