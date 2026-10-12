import 'dart:ui' show PointerDeviceKind;

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/overview/screen_catalog.dart';
import 'package:gallery/src/pages/screens/overview/screen_thumbnail.dart';
import 'package:gallery/src/pages/screens/shared/screen_variant.dart';
import 'package:gallery/src/shell/gallery_page.dart';
import 'package:gallery/src/shell/gallery_section.dart';

/// Abre a tela [screenId] — o nome do destino no menu — no estado
/// [variantIndex].
typedef OpenScreenState = void Function(String screenId, int variantIndex);

/// A vitrine de estados: todas as telas do app, em todos os estados, lado
/// a lado.
///
/// Os estados já existiam, mas cada um ficava atrás de um chip na página
/// da sua tela, e quem abria a gallery não os via juntos. Aqui cada tela
/// é uma fileira de miniaturas, e tocar numa abre a tela grande.
class ScreenStatesPage extends StatelessWidget {
  /// Cria a vitrine; tocar numa miniatura chama [onOpen].
  const new({required this.onOpen, super.key});

  /// Chamado com a tela e o estado tocados. Quem monta a vitrine decide
  /// como abrir a tela grande: ela não conhece a navegação da gallery.
  final OpenScreenState onOpen;

  /// O nome da página, o mesmo do menu.
  static const title = 'Estados das telas';

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final screen in ScreenCatalog.screens)
        (screen: screen, variants: screen.variants()),
    ];
    final total = rows.fold(0, (sum, row) => sum + row.variants.length);
    return GalleryPage(
      title: title,
      lead:
          'As ${rows.length} telas do app nos $total estados que podem '
          'viver — com dados, carregando, sem rede, primeiro uso —, lado a '
          'lado. Toque num estado para abrir a tela grande, já nele.',
      sections: [
        for (final row in rows)
          GallerySection(
            title: row.screen.title,
            description: '${row.variants.length} estados',
            child: _StateRow(
              screen: row.screen.title,
              variants: row.variants,
              onOpen: (index) => onOpen(row.screen.id, index),
            ),
          ),
      ],
    );
  }
}

/// A fileira de miniaturas de uma tela.
///
/// É preguiçosa: monta só as miniaturas perto da vista. Cada uma é uma tela
/// inteira, e o Comprovante sozinho tem dezoito.
class _StateRow extends StatelessWidget {
  const new({
    required this.screen,
    required this.variants,
    required this.onOpen,
  });

  final String screen;
  final List<ScreenVariant> variants;
  final ValueChanged<int> onOpen;

  /// No computador, a fileira também anda arrastando com o mouse: sem
  /// isso, só o trackpad ou o Shift com a rodinha a moveriam de lado.
  static final Set<PointerDeviceKind> _anyPointer = PointerDeviceKind.values
      .toSet();

  @override
  Widget build(BuildContext context) {
    final last = variants.length - 1;
    return SizedBox(
      height: ScreenThumbnail.height,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context)
            .copyWith(dragDevices: _anyPointer),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: variants.length,
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsets.only(
              right: index == last ? 0 : CajuiSpacing.lg,
            ),
            child: ScreenThumbnail(
              screen: screen,
              variant: variants[index],
              onOpen: () => onOpen(index),
            ),
          ),
        ),
      ),
    );
  }
}
