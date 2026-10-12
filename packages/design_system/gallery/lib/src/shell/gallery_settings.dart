import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/app/gallery_controller.dart';
import 'package:gallery/src/app/gallery_scope.dart';

/// Os ajustes que valem para a gallery inteira, num lugar só: tema, som,
/// movimento e a cor da falta.
///
/// Antes eles estavam espalhados — tema e som no pé do menu, o movimento em
/// cinco páginas e com dois nomes, a cor da falta em duas —, e mudar numa
/// página mudava as outras sem aviso. As páginas que demonstram um deles
/// ainda podem mostrar a escolha, mas o lugar dela é aqui.
class GallerySettings extends StatelessWidget {
  /// Cria o painel de ajustes.
  const new({super.key});

  static const Map<MotionLevel, String> _motion = {
    MotionLevel.full: 'Completo',
    MotionLevel.lite: 'Leve',
    MotionLevel.reduced: 'Reduzido',
  };

  /// Os ajustes em vigor, numa linha: "Claro · som desligado · completo".
  static String summaryOf(GalleryController controller) => [
    if (controller.brightness == Brightness.light) 'Claro' else 'Escuro',
    if (controller.sound.soundEnabled) 'som ligado' else 'som desligado',
    'movimento ${_motion[controller.motionLevel]!.toLowerCase()}',
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final controller = GalleryScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: CajuiSpacing.xl,
      children: [
        _theme(context, controller),
        _sound(context, controller),
        _motionLevel(context, controller),
        _shortfall(context, controller),
      ],
    );
  }

  Widget _theme(BuildContext context, GalleryController controller) => _Row(
    title: 'Tema',
    children: [
      for (final (brightness, label) in const [
        (Brightness.light, 'Claro'),
        (Brightness.dark, 'Escuro'),
      ])
        CajuiChip(
          label: label,
          selected: controller.brightness == brightness,
          onSelected: (_) => controller.useBrightness(brightness),
        ),
    ],
  );

  Widget _sound(BuildContext context, GalleryController controller) {
    final sound = controller.sound;
    return _Row(
      title: 'Som',
      note: 'Nasce desligado, como no app.',
      children: [
        CajuiChip(
          label: 'Som nas interações',
          selected: sound.soundEnabled,
          onSelected: (on) =>
              controller.useSound(sound.copyWith(soundEnabled: on)),
        ),
      ],
    );
  }

  Widget _motionLevel(BuildContext context, GalleryController controller) =>
      _Row(
        title: 'Nível de movimento',
        note: 'No app, vem do sistema e da medição de quadros.',
        children: [
          for (final MapEntry(key: level, value: label) in _motion.entries)
            CajuiChip(
              label: label,
              selected: controller.motionLevel == level,
              onSelected: (_) => controller.useMotionLevel(level),
            ),
        ],
      );

  Widget _shortfall(BuildContext context, GalleryController controller) => _Row(
    title: 'Cor da falta',
    note: 'Como aparece o dinheiro que falta no mês.',
    children: [
      for (final (style, label) in const [
        (ShortfallStyle.calm, 'Barro'),
        (ShortfallStyle.alarm, 'Vermelho'),
      ])
        CajuiChip(
          label: label,
          selected: controller.shortfallStyle == style,
          onSelected: (_) => controller.useShortfallStyle(style),
        ),
    ],
  );
}

/// Um ajuste: o nome, a explicação curta e as escolhas.
class _Row extends StatelessWidget {
  const new({required this.title, required this.children, this.note});

  final String title;
  final String? note;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final explanation = note;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.typography.label.copyWith(
            color: theme.colors.text.primary,
          ),
        ),
        if (explanation != null)
          Text(
            explanation,
            style: theme.typography.caption.copyWith(
              color: theme.colors.text.muted,
            ),
          ),
        const SizedBox(height: CajuiSpacing.sm),
        Wrap(
          spacing: CajuiSpacing.sm,
          runSpacing: CajuiSpacing.sm,
          children: children,
        ),
      ],
    );
  }
}
