import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/alive/card_section.dart';
import 'package:gallery/src/pages/alive/chart_section.dart';
import 'package:gallery/src/pages/alive/device_tilt.dart';
import 'package:gallery/src/pages/alive/glow_section.dart';
import 'package:gallery/src/pages/alive/numbers_section.dart';
import 'package:gallery/src/pages/alive/seed_leaf_section.dart';
import 'package:gallery/src/pages/alive/streaming_section.dart';
import 'package:gallery/src/shell/gallery_page.dart';

/// Os efeitos vivos: o que faz o app parecer de verdade sem atrapalhar o uso.
///
/// Cada um nasce com a versão parada — troque o nível de movimento na mesa
/// de movimento para conferir —, e nenhum roda em laço.
class AlivePage extends StatefulWidget {
  /// Cria a página.
  const new({super.key});

  @override
  State<AlivePage> createState() => _AlivePageState();
}

class _AlivePageState extends State<AlivePage> {
  /// O que o arrasto escreve.
  final ValueNotifier<Offset> _drag = ValueNotifier(Offset.zero);

  /// O que move o cartão: o arrasto somado ao celular de quem visita.
  final ValueNotifier<Offset> _tilt = ValueNotifier(Offset.zero);

  late final DeviceTilt _device = DeviceTilt(_heard);
  Offset _phone = Offset.zero;

  @override
  void initState() {
    super.initState();
    _drag.addListener(_mix);
    _device.start();
  }

  void _heard(Offset phone) {
    _phone = phone;
    _mix();
  }

  void _mix() {
    final sum = _drag.value + _phone;
    _tilt.value = Offset(
      sum.dx.clamp(-1, 1).toDouble(),
      sum.dy.clamp(-1, 1).toDouble(),
    );
  }

  @override
  void dispose() {
    _device.stop();
    _drag.dispose();
    _tilt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Microinterações',
      lead:
          'Cartão que inclina, número que rola e voa, '
          'semente que cai. Tudo respeita o movimento reduzido do sistema, '
          'assenta sozinho e nunca fica no caminho de quem usa.',
      sections: [
        CardSection(tilt: _tilt, drag: _drag),
        const NumbersSection(),
        const SeedLeafSection(),
        const GlowSection(),
        const ChartSection(),
        const StreamingSection(),
      ],
    );
  }
}
