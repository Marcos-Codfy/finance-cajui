import 'package:design_system/src/accessibility/contrast_pair.dart';
import 'package:design_system/src/accessibility/contrast_requirement.dart';
import 'package:design_system/src/tokens/semantic/cajui_colors.dart';
import 'package:flutter/painting.dart';

/// A lista de todo par de cores que o design system usa junto.
///
/// É a fonte única do RNF-A11Y-02: o teste percorre esta lista e quebra o
/// build se um par cair abaixo do mínimo, e a gallery exibe a mesma lista.
/// Componente novo que junta duas cores de um jeito novo declara o par aqui.
abstract final class ContrastAudit {
  /// Todos os pares de um tema.
  static List<ContrastPair> pairsFor(CajuiColors colors) => [
    ..._textOnSurfaces(colors),
    ..._textOnActions(colors),
    ..._intents(colors),
    ..._componentEdges(colors),
    ..._dataMarks(colors),
  ];

  static Map<String, Color> _surfaces(CajuiColors c) => {
    'surface.base': c.surface.base,
    'surface.sunken': c.surface.sunken,
    'surface.elevated': c.surface.elevated,
    'surface.high': c.surface.high,
  };

  static List<ContrastPair> _textOnSurfaces(CajuiColors c) {
    final texts = {
      'text.primary': c.text.primary,
      'text.muted': c.text.muted,
      'text.faint': c.text.faint,
      'text.link': c.text.link,
      // O botão discreto escreve o rótulo com a cor de ação.
      'action.primary (texto)': c.action.primary,
      'shortfall': c.shortfall,
    };
    return _cross(texts, _surfaces(c), ContrastRequirement.text);
  }

  static List<ContrastPair> _textOnActions(CajuiColors c) => [
    ..._cross(
      {'text.onAction': c.text.onAction},
      {
        'action.primary': c.action.primary,
        'action.primaryHover': c.action.primaryHover,
        'action.primaryPressed': c.action.primaryPressed,
        // Botão destrutivo.
        'intent.danger': c.intent.danger,
      },
      ContrastRequirement.text,
    ),
    ..._cross(
      {'text.primary': c.text.primary},
      {
        'action.secondary': c.action.secondary,
        'action.secondaryHover': c.action.secondaryHover,
        'action.secondaryPressed': c.action.secondaryPressed,
      },
      ContrastRequirement.text,
    ),
  ];

  static List<ContrastPair> _intents(CajuiColors c) {
    final i = c.intent;
    final pairs = {
      'intent.positive': (i.positive, i.positiveSubtle),
      'intent.notice': (i.notice, i.noticeSubtle),
      'intent.danger': (i.danger, i.dangerSubtle),
      'intent.info': (i.info, i.infoSubtle),
      'intent.achievement': (i.achievement, i.achievementSubtle),
    };
    return [
      for (final MapEntry(:key, :value) in pairs.entries) ...[
        // O aviso escreve o texto comum sobre o fundo sutil da intenção.
        ..._cross(
          {'text.primary': c.text.primary, 'text.muted': c.text.muted},
          {'${key}Subtle': value.$2},
          ContrastRequirement.text,
        ),
        ..._cross(
          {key: value.$1},
          {
            'surface.base': c.surface.base,
            'surface.elevated': c.surface.elevated,
            '${key}Subtle': value.$2,
          },
          ContrastRequirement.text,
        ),
      ],
    ];
  }

  static List<ContrastPair> _componentEdges(CajuiColors c) => [
    ..._cross(
      {
        'border.field': c.border.field,
        // Contorno de campo com foco e com erro.
        'border.strong': c.border.strong,
        'intent.notice (contorno)': c.intent.notice,
      },
      _surfaces(c),
      ContrastRequirement.largeTextOrComponent,
    ),
    ..._cross(
      {'focus.ring': c.border.focusRing},
      {'focus.gap': c.border.focusGap},
      ContrastRequirement.largeTextOrComponent,
    ),
    ..._cross(
      {'focus.gap': c.border.focusGap},
      {'action.primary': c.action.primary},
      ContrastRequirement.largeTextOrComponent,
    ),
  ];

  static List<ContrastPair> _dataMarks(CajuiColors c) => _cross(
    {
      'data.fixed': c.data.fixed,
      'data.variable': c.data.variable,
      'data.debt': c.data.debt,
      'data.voucher': c.data.voucher,
      'brand.accent': c.brand.accent,
    },
    {
      'surface.base': c.surface.base,
      'surface.elevated': c.surface.elevated,
      'data.track': c.data.track,
    },
    ContrastRequirement.largeTextOrComponent,
  );

  static List<ContrastPair> _cross(
    Map<String, Color> foregrounds,
    Map<String, Color> backgrounds,
    ContrastRequirement requirement,
  ) => [
    for (final fg in foregrounds.entries)
      for (final bg in backgrounds.entries)
        ContrastPair(
          foregroundName: fg.key,
          backgroundName: bg.key,
          foreground: fg.value,
          background: bg.value,
          requirement: requirement,
        ),
  ];
}
