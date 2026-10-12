import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/app/gallery_location.dart';
import 'package:gallery/src/shell/gallery_destination.dart';
import 'package:gallery/src/shell/gallery_shell.dart';

/// Guarda a página aberta e a entrega à casca.
///
/// Cada troca de página vira uma entrada no histórico do navegador: o
/// Voltar volta para a página de antes, em vez de sair da gallery, e
/// recarregar mantém a página aberta.
class GalleryRouter extends RouterDelegate<GalleryLocation>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<GalleryLocation> {
  /// Cria o roteador, aberto na porta de entrada.
  new();

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  GalleryLocation _location = (
    page: GalleryDestination.values.first,
    state: null,
  );

  @override
  GalleryLocation get currentConfiguration => _location;

  /// Abre [page], no estado [state] se for uma tela do app.
  void open(GalleryDestination page, {String? state}) {
    if (page == _location.page && state == _location.state) return;
    _location = (page: page, state: state);
    notifyListeners();
  }

  @override
  Future<void> setNewRoutePath(GalleryLocation configuration) {
    _location = configuration;
    notifyListeners();
    return SynchronousFuture(null);
  }

  /// Um navegador com uma página só, a casca. Ele existe porque o campo de
  /// texto precisa de uma camada por cima (a seleção, o cursor), e os
  /// painéis de menu e de ajustes se fecham pelo Voltar do Android.
  @override
  Widget build(BuildContext context) => Navigator(
    key: navigatorKey,
    pages: [_ShellPage(router: this)],
    onDidRemovePage: (_) {},
  );
}

/// A página única do navegador. A chave não muda: trocar de página da
/// gallery não troca de rota, só reconstrói a casca.
class _ShellPage extends Page<void> {
  const new({required this.router}) : super(key: const ValueKey('shell'));

  final GalleryRouter router;

  @override
  Route<void> createRoute(BuildContext context) => PageRouteBuilder<void>(
    settings: this,
    pageBuilder: (context, _, _) => ListenableBuilder(
      listenable: router,
      builder: (context, _) => GalleryShell(
        location: router.currentConfiguration,
        onOpen: router.open,
      ),
    ),
  );
}
