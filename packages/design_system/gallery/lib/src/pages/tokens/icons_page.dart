import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/shell/gallery_page.dart';
import 'package:gallery/src/shell/gallery_section.dart';

/// Todos os ícones, nos dois tamanhos que a interface usa.
///
/// A lista **percorre o enum**, e não uma cópia escrita à mão: ícone novo
/// aparece aqui no mesmo commit em que nasce, sem ninguém precisar lembrar.
/// Uma gallery que mostra menos do que o design system tem é pior que
/// nenhuma — ela mente sobre o que existe.
class IconsPage extends StatelessWidget {
  /// Cria a página de ícones.
  const new({super.key});

  /// O tamanho grande, de estado vazio e de cabeçalho.
  static const double _largeSize = 40;

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Ícones',
      lead:
          'Desenhados como caminhos numa grade de 24, e não como fonte nem '
          'SVG: o design system fica sem dependência, o traço vale para '
          'todos e a cor é sempre herdada de quem os contém.',
      sections: [_all(), _large()],
    );
  }

  GallerySection _all() => GallerySection(
    title: '${CajuiIconData.values.length} ícones',
    description:
        'Os conceitos próprios do produto têm desenho próprio: o vale é um '
        'cartão com garfo — vale não é dinheiro, então nada de cifrão — e a '
        'dívida é uma escada que desce, porque parcela acaba.',
    child: _wrap([
      for (final icon in CajuiIconData.values) _Sample(icon: icon),
    ]),
  );

  GallerySection _large() => GallerySection(
    title: 'No tamanho grande',
    description: 'O mesmo caminho, redesenhado — nunca uma imagem esticada.',
    child: _wrap([
      for (final icon in CajuiIconData.values)
        CajuiIcon(icon, size: _largeSize),
    ]),
  );

  Widget _wrap(List<Widget> children) => Wrap(
    spacing: CajuiSpacing.xl,
    runSpacing: CajuiSpacing.xl,
    children: children,
  );
}

class _Sample extends StatelessWidget {
  const new({required this.icon});

  final CajuiIconData icon;

  static const double _width = 96;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return SizedBox(
      width: _width,
      child: Column(
        children: [
          CajuiIcon(icon),
          const SizedBox(height: CajuiSpacing.sm),
          Text(
            icon.name,
            textAlign: TextAlign.center,
            style: theme.typography.label.copyWith(
              color: theme.colors.text.muted,
            ),
          ),
        ],
      ),
    );
  }
}
