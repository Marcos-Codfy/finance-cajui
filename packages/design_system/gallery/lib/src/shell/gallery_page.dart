import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/shell/gallery_destination.dart';
import 'package:gallery/src/shell/gallery_page_turn.dart';
import 'package:gallery/src/shell/gallery_pager.dart';

/// A moldura de toda página da gallery: título, uma frase que diz para que a
/// página serve, e as seções, numa coluna rolável de largura confortável.
///
/// Dentro da casca, ganha em cima onde a página está ("Componentes · 2 de
/// 5") e embaixo a anterior e a próxima.
class GalleryPage extends StatelessWidget {
  /// Cria a página com [title], a frase [lead] e as [sections].
  const new({
    required this.title,
    required this.lead,
    required this.sections,
    super.key,
  });

  /// O título da página.
  final String title;

  /// Para que a página serve, em uma ou duas frases.
  final String lead;

  /// As seções, de cima para baixo.
  final List<Widget> sections;

  /// Largura máxima do conteúdo: além disso, a linha de texto fica longa
  /// demais para ler.
  static const double _maxWidth = 960;

  /// A frase de abertura lê melhor em linha mais curta que a página.
  static const double _leadWidth = 720;

  @override
  Widget build(BuildContext context) {
    final pager = GalleryPager.maybeOf(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: CajuiSpacing.xxl,
        vertical: CajuiSpacing.section,
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._header(context, pager?.current),
              ...sections,
              if (pager != null) GalleryPageTurn(pager: pager),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _header(BuildContext context, GalleryDestination? current) {
    final theme = CajuiTheme.of(context);
    return [
      if (current != null) ..._where(theme, current),
      Semantics(
        header: true,
        child: Text(
          title,
          style: theme.typography.displayMedium.copyWith(
            color: theme.colors.text.primary,
          ),
        ),
      ),
      const SizedBox(height: CajuiSpacing.sm),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _leadWidth),
        child: Text(
          lead,
          style: theme.typography.body.copyWith(color: theme.colors.text.muted),
        ),
      ),
      const SizedBox(height: CajuiSpacing.section),
    ];
  }

  List<Widget> _where(CajuiThemeData theme, GalleryDestination current) => [
    Text(
      _whereIs(current),
      style: theme.typography.overline.copyWith(color: theme.colors.text.faint),
    ),
    const SizedBox(height: CajuiSpacing.xs),
  ];

  /// "COMPONENTES · 2 DE 5": o grupo e a posição da página dentro dele.
  static String _whereIs(GalleryDestination current) {
    final siblings = GalleryDestination.inGroup(current.group).toList();
    final position = siblings.indexOf(current) + 1;
    // Grupo de uma página só não precisa de "1 de 1".
    final where = siblings.length == 1
        ? current.group.title
        : '${current.group.title} · $position de ${siblings.length}';
    return where.toUpperCase();
  }
}
