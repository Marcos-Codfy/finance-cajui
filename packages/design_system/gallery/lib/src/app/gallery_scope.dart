import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/app/gallery_controller.dart';

/// Entrega o [GalleryController] às páginas e as reconstrói quando ele muda.
///
/// Leva junto o tocador de som: a mesa de som toca cada arquivo direto, sem
/// passar pela resposta de interação, para que dê para ouvir um som mesmo
/// com a categoria dele desligada.
class GalleryScope extends InheritedNotifier<GalleryController> {
  /// Publica o [controller] e o [player] para a árvore abaixo.
  const new({
    required GalleryController controller,
    required this.player,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  /// O tocador de som da gallery.
  final SoundPlayer player;

  static GalleryScope _of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<GalleryScope>();
    assert(scope != null, 'Nenhum GalleryScope acima deste widget.');
    return scope!;
  }

  /// O controlador mais próximo acima de [context].
  static GalleryController of(BuildContext context) => _of(context).notifier!;

  /// O tocador de som mais próximo acima de [context].
  static SoundPlayer playerOf(BuildContext context) => _of(context).player;
}
