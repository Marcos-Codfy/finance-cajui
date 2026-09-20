import 'package:gallery/src/shell/gallery_group.dart';

/// Cada página da gallery.
///
/// É um enum, e não uma lista, para que o `switch` que monta a página seja
/// exaustivo: acrescentar um destino sem acrescentar a página não compila.
enum GalleryDestination {
  /// Os papéis de cor, no tema em vigor.
  colors('Cores', GalleryGroup.foundations),

  /// A tabela de contraste, calculada ao vivo.
  contrast('Contraste', GalleryGroup.foundations),

  /// A escala tipográfica.
  typography('Tipografia', GalleryGroup.foundations),

  /// Espaçamento, raio e elevação.
  layout('Espaço, raio e sombra', GalleryGroup.foundations);

  new(this.title, this.group);

  /// O nome da página no menu.
  final String title;

  /// O grupo do menu a que a página pertence.
  final GalleryGroup group;

  /// As páginas de um [group], na ordem do menu.
  static Iterable<GalleryDestination> inGroup(GalleryGroup group) =>
      values.where((destination) => destination.group == group);
}
