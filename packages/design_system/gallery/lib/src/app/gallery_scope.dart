import 'package:flutter/widgets.dart';
import 'package:gallery/src/app/gallery_controller.dart';

/// Entrega o [GalleryController] às páginas e as reconstrói quando ele muda.
class GalleryScope extends InheritedNotifier<GalleryController> {
  /// Publica o [controller] para a árvore abaixo.
  const new({
    required GalleryController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  /// O controlador mais próximo acima de [context].
  static GalleryController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<GalleryScope>();
    assert(scope != null, 'Nenhum GalleryScope acima deste widget.');
    return scope!.notifier!;
  }
}
