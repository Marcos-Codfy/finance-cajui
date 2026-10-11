import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/alive/tilt_pad.dart';
import 'package:gallery/src/shell/gallery_section.dart';

/// O pote de água: o "pode gastar" da semana, que esvazia a cada gasto e
/// balança com a inclinação.
class WaterSection extends StatefulWidget {
  /// Cria a seção, ligada à inclinação de mentira [tilt].
  const new({required this.tilt, super.key});

  /// A inclinação compartilhada com o cartão.
  final ValueNotifier<Offset> tilt;

  @override
  State<WaterSection> createState() => _WaterSectionState();
}

class _WaterSectionState extends State<WaterSection> {
  /// Valores fictícios: limite de R$ 400,00 na semana, R$ 188,00 já usados.
  static const int _limit = 40000;
  static const int _purchase = 3840;
  int _spent = 18800;

  int get _left => _limit - _spent;

  String get _caption {
    if (_left >= 0) return 'de ${BrlFormatter.format(_limit)} · até domingo';
    return 'Passou ${BrlFormatter.format(-_left)} do limite da semana';
  }

  /// Um chacoalhão de mentira: a mão vai e volta e solta. A água segue
  /// balançando sozinha depois.
  Future<void> _shake() async {
    for (final side in const [0.7, -0.6, 0.35, 0.0]) {
      widget.tilt.value = Offset(side, 0);
      await Future<void>.delayed(CajuiDurations.fast);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Pote de água',
      description:
          'Pode gastar esta semana como água num pote: esvazia a cada gasto e '
          'balança com o celular. Arraste o quadrado para inclinar. A água '
          'assenta sozinha em uns dois segundos; no movimento reduzido, é um '
          'desenho parado.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: CajuiSpacing.xxl,
            runSpacing: CajuiSpacing.lg,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _gauge(),
              TiltPad(tilt: widget.tilt),
            ],
          ),
          const SizedBox(height: CajuiSpacing.lg),
          _actions(),
        ],
      ),
    );
  }

  Widget _gauge() {
    return SizedBox(
      width: 320,
      child: CajuiCard(
        child: CajuiWaterGauge(
          fraction: (_left / _limit).clamp(0, 1).toDouble(),
          cents: _left,
          label: 'Pode gastar esta semana',
          caption: _caption,
          tilt: widget.tilt,
        ),
      ),
    );
  }

  Widget _actions() {
    return Wrap(
      spacing: CajuiSpacing.sm,
      runSpacing: CajuiSpacing.sm,
      children: [
        CajuiButton(
          label: 'Gastar ${BrlFormatter.format(_purchase)}',
          size: CajuiButtonSize.compact,
          onPressed: () => setState(() => _spent += _purchase),
        ),
        CajuiButton(
          label: 'Chacoalhar',
          size: CajuiButtonSize.compact,
          variant: CajuiButtonVariant.secondary,
          onPressed: () => unawaited(_shake()),
        ),
        CajuiButton(
          label: 'Começar a semana',
          size: CajuiButtonSize.compact,
          variant: CajuiButtonVariant.ghost,
          onPressed: () => setState(() => _spent = 0),
        ),
      ],
    );
  }
}
