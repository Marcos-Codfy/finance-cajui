import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/app/gallery_location.dart';
import 'package:gallery/src/pages/screens/overview/screen_catalog.dart';
import 'package:gallery/src/shell/gallery_destination.dart';

/// Traduz o endereço em página, e a página em endereço.
///
/// Na web o Flutter usa o endereço com `#`: `/gallery/#/widget`. Assim a
/// Vercel não precisa de regra nenhuma — o servidor sempre entrega o mesmo
/// `index.html`, e o resto do caminho só existe no navegador.
class GalleryRouteParser extends RouteInformationParser<GalleryLocation> {
  /// Cria o tradutor.
  const new();

  /// O parâmetro do estado de uma tela: `?estado=sem-rede`.
  static const stateKey = 'estado';

  @override
  Future<GalleryLocation> parseRouteInformation(
    RouteInformation routeInformation,
  ) => SynchronousFuture(locationOf(routeInformation.uri));

  @override
  RouteInformation restoreRouteInformation(GalleryLocation configuration) {
    final state = configuration.state;
    return RouteInformation(
      uri: Uri(
        path: '/${configuration.page.slug}',
        queryParameters: state == null ? null : {stateKey: state},
      ),
    );
  }

  /// A página do endereço [uri]. Endereço vazio ou desconhecido — link
  /// velho, erro de digitação — abre a porta de entrada, e não uma tela de
  /// erro.
  static GalleryLocation locationOf(Uri uri) {
    final slugs = uri.pathSegments.where((segment) => segment.isNotEmpty);
    final page = slugs.isEmpty ? null : GalleryDestination.bySlug(slugs.first);
    final state = uri.queryParameters[stateKey];
    final known =
        page != null &&
        state != null &&
        ScreenCatalog.hasState(page.name, state);
    return (
      page: page ?? GalleryDestination.values.first,
      state: known ? state : null,
    );
  }
}
