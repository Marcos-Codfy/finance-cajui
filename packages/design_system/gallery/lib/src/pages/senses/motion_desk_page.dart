import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/app/gallery_scope.dart';
import 'package:gallery/src/pages/senses/curve_track.dart';
import 'package:gallery/src/shell/gallery_page.dart';
import 'package:gallery/src/shell/gallery_section.dart';

/// A mesa de movimento: os tokens de tempo e de curva, os efeitos da marca e
/// os três níveis de qualidade, para ver cada um degradar.
class MotionDeskPage extends StatefulWidget {
  /// Cria a mesa de movimento.
  const new({super.key});

  @override
  State<MotionDeskPage> createState() => _MotionDeskPageState();
}

class _MotionDeskPageState extends State<MotionDeskPage> {
  static const Map<MotionLevel, String> _levels = {
    MotionLevel.full: 'Completo',
    MotionLevel.lite: 'Leve',
    MotionLevel.reduced: 'Reduzido',
  };

  /// O uso vem primeiro, em português; a curva e a duração, pelo token.
  static const Map<String, (Curve, Duration)> _tracks = {
    'Resposta a toque · spring · fast (180 ms)': (
      CajuiCurves.spring,
      CajuiDurations.fast,
    ),
    'Algo entrando · enter · base (260 ms)': (
      CajuiCurves.enter,
      CajuiDurations.base,
    ),
    'Troca de tela · standard · slow (420 ms)': (
      CajuiCurves.standard,
      CajuiDurations.slow,
    ),
    'Algo saindo · exit · fast (180 ms)': (
      CajuiCurves.exit,
      CajuiDurations.fast,
    ),
  };

  int _run = 0;
  int _cents = 19600;

  void _replay() {
    setState(() {
      _run++;
      _cents = _cents == 19600 ? 22647 : 19600;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Mesa de movimento',
      lead:
          'Macio, próximo, natural: nada bate, nada pisca. Todo efeito nasce '
          'com a sua versão parada — troque o nível e rode de novo para ver.',
      sections: [_levelChooser(context), _curves(), _effects(context)],
    );
  }

  Widget _levelChooser(BuildContext context) {
    final controller = GalleryScope.of(context);
    return GallerySection(
      title: 'Nível de movimento',
      description:
          'No app, o nível vem do sistema (movimento reduzido), depois da '
          'medição de quadros no aparelho, e só então da preferência. Aqui '
          'a escolha é manual e vale para a gallery inteira.',
      child: Wrap(
        spacing: CajuiSpacing.sm,
        runSpacing: CajuiSpacing.sm,
        children: [
          for (final MapEntry(key: level, value: label) in _levels.entries)
            CajuiChip(
              label: label,
              selected: controller.motionLevel == level,
              onSelected: (_) => controller.useMotionLevel(level),
            ),
          CajuiButton(
            label: 'Rodar de novo',
            size: CajuiButtonSize.compact,
            onPressed: _replay,
          ),
        ],
      ),
    );
  }

  Widget _curves() {
    return GallerySection(
      title: 'Curvas e durações',
      description:
          'Nada passa de 600 ms. A mola ultrapassa o destino e volta: é o que '
          'faz o toque parecer físico.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final MapEntry(key: name, value: (curve, duration))
              in _tracks.entries)
            _track(name, curve, duration),
        ],
      ),
    );
  }

  Widget _track(String name, Curve curve, Duration duration) {
    final theme = CajuiTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: theme.typography.caption.copyWith(
              color: theme.colors.text.muted,
            ),
          ),
          const SizedBox(height: CajuiSpacing.xs),
          CurveTrack(curve: curve, duration: duration, run: _run),
        ],
      ),
    );
  }

  Widget _effects(BuildContext context) {
    return GallerySection(
      title: 'Efeitos da marca',
      description:
          'Lista em cascata e número que conta até o valor. No nível '
          'reduzido, os dois aparecem prontos.',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CajuiCountUp(
              value: _cents,
              builder: (_, cents) => CajuiAmountText(cents, large: true),
            ),
            const SizedBox(height: CajuiSpacing.lg),
            KeyedSubtree(key: ValueKey(_run), child: const _Cascade()),
          ],
        ),
      ),
    );
  }
}

class _Cascade extends StatelessWidget {
  const new();

  static const _rows = [
    ('Mercado', 'Vale alimentação', 3840),
    ('Farmácia', 'Crédito · 2 de 3', 4590),
    ('Corrida de app', 'Pix', 1870),
    ('Padaria', 'Débito', 850),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (index, (what, paidWith, cents)) in _rows.indexed)
          CajuiEntrance(
            index: index,
            child: CajuiListRow(
              title: what,
              subtitle: paidWith,
              trailing: CajuiAmountText(cents),
            ),
          ),
      ],
    );
  }
}
