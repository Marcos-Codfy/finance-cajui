import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/shell/gallery_destination.dart';
import 'package:gallery/src/shell/gallery_pager.dart';

/// Os seis atalhos da porta de entrada: o que o projeto tem de diferente.
///
/// Cada um é um cartão tocável que leva à página — o recrutador que só tem
/// um minuto vai direto ao que importa, sem procurar no menu.
class OverviewHighlights extends StatelessWidget {
  /// Cria os atalhos.
  const new({super.key});

  static const List<(GalleryDestination, String, String)> _all = [
    (
      GalleryDestination.screenStates,
      'O app em todos os estados',
      'Com dados, carregando, sem rede, primeiro uso — tela por tela.',
    ),
    (
      GalleryDestination.assistant,
      'Juju, a assistente',
      'Lança o gasto que você diz e confere o extrato por blocos.',
    ),
    (
      GalleryDestination.homeWidget,
      'Widget de vidro',
      'Vidro sobre a aurora, e o app que nasce de dentro dele.',
    ),
    (
      GalleryDestination.coverFlow,
      'Carrossel 3D',
      'Os números do mês num tambor, com mola, som e três níveis.',
    ),
    (
      GalleryDestination.soundDesk,
      'Mesa de som',
      'Cada som masterizado para o alto-falante do celular.',
    ),
    (
      GalleryDestination.doDont,
      'Faça e evite',
      'As regras próprias do Cajui: a falta sem bronca, o cartão, o vale.',
    ),
  ];

  static const double _cardWidth = 296;

  /// Quando não cabem dois lado a lado, cada cartão ocupa a coluna inteira:
  /// com a largura fixa, no celular sobrava uma faixa vazia à direita.
  @override
  Widget build(BuildContext context) {
    final pager = GalleryPager.maybeOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final room = constraints.maxWidth;
        final width = room < 2 * _cardWidth + CajuiSpacing.lg
            ? room
            : _cardWidth;
        return Wrap(
          spacing: CajuiSpacing.lg,
          runSpacing: CajuiSpacing.lg,
          children: [
            for (final (page, title, line) in _all)
              SizedBox(
                width: width,
                child: _Highlight(
                  title: title,
                  line: line,
                  onPressed: pager == null ? null : () => pager.onOpen(page),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Highlight extends StatelessWidget {
  const new({required this.title, required this.line, this.onPressed});

  final String title;
  final String line;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return CajuiCard(
      onPressed: onPressed,
      semanticLabel: '$title. $line',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: CajuiSpacing.md,
        children: [
          Expanded(child: _words(theme)),
          CajuiIcon(CajuiIconData.chevronRight, color: theme.colors.text.faint),
        ],
      ),
    );
  }

  Widget _words(CajuiThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: CajuiSpacing.xs,
    children: [
      Text(
        title,
        style: theme.typography.bodyStrong.copyWith(
          color: theme.colors.text.primary,
        ),
      ),
      Text(
        line,
        style: theme.typography.caption.copyWith(
          color: theme.colors.text.muted,
        ),
      ),
    ],
  );
}
