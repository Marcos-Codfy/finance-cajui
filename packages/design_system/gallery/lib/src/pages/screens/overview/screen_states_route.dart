import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/overview/screen_catalog.dart';
import 'package:gallery/src/pages/screens/overview/screen_states_page.dart';
import 'package:gallery/src/pages/screens/shared/variant_slug.dart';
import 'package:gallery/src/shell/gallery_destination.dart';
import 'package:gallery/src/shell/gallery_pager.dart';

/// A vitrine de estados ligada à navegação da gallery: tocar numa
/// miniatura abre a tela grande já no estado tocado, com o estado no
/// endereço (`/gallery/#/inicio?estado=sem-rede`).
///
/// A vitrine em si não conhece a casca — recebe só um `onOpen` —; é aqui
/// que o id da tela vira destino do menu e o índice vira nome de estado.
class ScreenStatesRoute extends StatelessWidget {
  /// Cria a vitrine ligada.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenStatesPage(
      onOpen: (screenId, variantIndex) =>
          _open(context, screenId, variantIndex),
    );
  }

  void _open(BuildContext context, String screenId, int variantIndex) {
    final pager = GalleryPager.maybeOf(context);
    if (pager == null) return;
    final screen = ScreenCatalog.screens.firstWhere((s) => s.id == screenId);
    final label = screen.variants()[variantIndex].label;
    pager.onOpen(
      GalleryDestination.values.byName(screenId),
      state: variantSlug(label),
    );
  }
}
