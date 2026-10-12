import 'package:flutter/widgets.dart';
import 'package:gallery/src/app/gallery_location.dart';
import 'package:gallery/src/shell/gallery_destination.dart';

/// A página aberta e o jeito de ir para outra, para quem está dentro dela.
///
/// O sobretítulo de cada página ("Componentes · 2 de 5") e o rodapé com a
/// anterior e a próxima leem daqui: sem isso, para seguir era preciso voltar
/// ao menu — e, no celular, achar o chip na fileira. Página montada sozinha,
/// sem a casca por cima (como nos testes de componente), fica sem os dois.
class GalleryPager extends InheritedWidget {
  /// Publica a página [current], o [onOpen] para ir a outra e o [onState]
  /// para a tela do app avisar que trocou de estado.
  const new({
    required this.current,
    required this.onOpen,
    required super.child,
    this.onState,
    super.key,
  });

  /// A página aberta.
  final GalleryDestination current;

  /// Leva a outra página — numa tela do app, já no estado pedido.
  final GalleryOpen onOpen;

  /// A tela do app trocou de estado: o endereço acompanha, sem virar uma
  /// entrada nova no histórico a cada toque no seletor.
  final ValueChanged<String>? onState;

  /// O mais próximo acima de [context], se houver.
  static GalleryPager? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GalleryPager>();

  /// A página antes desta, na ordem do menu; nenhuma na primeira.
  GalleryDestination? get previous =>
      current.index == 0 ? null : GalleryDestination.values[current.index - 1];

  /// A página depois desta; nenhuma na última.
  GalleryDestination? get next => current.index == _last
      ? null
      : GalleryDestination.values[current.index + 1];

  static int get _last => GalleryDestination.values.length - 1;

  @override
  bool updateShouldNotify(GalleryPager oldWidget) =>
      current != oldWidget.current || onOpen != oldWidget.onOpen;
}
