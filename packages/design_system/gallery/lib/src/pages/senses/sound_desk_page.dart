import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/app/gallery_scope.dart';
import 'package:gallery/src/pages/senses/sound_notes.dart';
import 'package:gallery/src/shell/gallery_page.dart';
import 'package:gallery/src/shell/gallery_section.dart';

/// A mesa de som: ouvir e aprovar cada som antes de ele entrar no app.
class SoundDeskPage extends StatelessWidget {
  /// Cria a mesa de som.
  const new({super.key});

  static const Map<String, double> _volumes = {
    'Baixo': 0.3,
    'Médio': 0.6,
    'Alto': 1,
  };

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Mesa de som',
      lead:
          'Dez sons curtos, secos e baixos, sintetizados pelo próprio '
          'projeto. O botão Tocar sempre toca, mesmo com o som do app '
          'desligado: aqui é audição. Não existe som de erro.',
      sections: [
        _preferences(context),
        for (final category in SoundCategory.values) _family(category),
      ],
    );
  }

  Widget _preferences(BuildContext context) {
    final controller = GalleryScope.of(context);
    final sound = controller.sound;
    return GallerySection(
      title: 'Preferências',
      description:
          'As mesmas do app. O som nasce desligado; o volume fica bem abaixo '
          'do de uma notificação. Ligue o som e toque nos controles da '
          'gallery para ouvir em uso.',
      child: Wrap(
        spacing: CajuiSpacing.sm,
        runSpacing: CajuiSpacing.sm,
        children: [
          CajuiChip(
            label: 'Som nas interações',
            selected: sound.soundEnabled,
            onSelected: (on) =>
                controller.useSound(sound.copyWith(soundEnabled: on)),
          ),
          for (final MapEntry(key: label, value: volume) in _volumes.entries)
            CajuiChip(
              label: 'Volume $label',
              selected: sound.volume == volume,
              onSelected: (_) =>
                  controller.useSound(sound.copyWith(volume: volume)),
            ),
        ],
      ),
    );
  }

  Widget _family(SoundCategory category) {
    final sounds = CajuiSound.values.where(
      (sound) => sound.category == category,
    );
    return GallerySection(
      title: category.label,
      child: Column(children: [for (final sound in sounds) _SoundRow(sound)]),
    );
  }
}

class _SoundRow extends StatelessWidget {
  const new(this.sound);

  final CajuiSound sound;

  /// Toca direto pelo tocador, na velocidade original: na mesa se ouve o
  /// arquivo como ele é; a variação fica para o uso de verdade.
  void _play(BuildContext context) {
    final volume = GalleryScope.of(context).sound.volume;
    GalleryScope.playerOf(context).play(sound, volume: volume, rate: 1);
  }

  @override
  Widget build(BuildContext context) {
    final note = SoundNotes.all[sound]!;
    return CajuiListRow(
      title: 'sound.${sound.name} · ${note.milliseconds} ms',
      subtitle: '${note.timbre}. ${note.use}.',
      leading: const CajuiIcon(CajuiIconData.sound, size: 20),
      // O botão da mesa não faz o som de toque: senão ele tocaria por cima
      // do som que se quer ouvir.
      trailing: CajuiFeedbackScope(
        feedback: const SilentFeedback(),
        child: CajuiButton(
          label: 'Tocar',
          size: CajuiButtonSize.compact,
          variant: CajuiButtonVariant.secondary,
          onPressed: () => _play(context),
        ),
      ),
    );
  }
}
