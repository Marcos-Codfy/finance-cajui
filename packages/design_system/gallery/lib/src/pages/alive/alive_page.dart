import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/alive/card_section.dart';
import 'package:gallery/src/pages/alive/chart_section.dart';
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
  /// A inclinação de mentira, a mesma para o pote e para o cartão: no app,
  /// é o acelerômetro que escreve aqui.
  final ValueNotifier<Offset> _tilt = ValueNotifier(Offset.zero);

  @override
  void dispose() {
    _tilt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Efeitos vivos',
      lead:
          'Cartão que inclina, número que rola e voa, '
          'semente que cai. Tudo respeita o movimento reduzido do sistema, '
          'assenta sozinho e nunca fica no caminho de quem usa.',
      sections: [
        CardSection(tilt: _tilt),
        const NumbersSection(),
        const SeedLeafSection(),
        const GlowSection(),
        const ChartSection(),
        const StreamingSection(),
      ],
    );
  }
}
