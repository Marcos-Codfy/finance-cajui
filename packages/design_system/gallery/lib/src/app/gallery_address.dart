import 'package:flutter/widgets.dart';
import 'package:gallery/src/app/gallery_route_parser.dart';

/// O endereço do navegador, que só cria entrada no histórico quando a
/// página muda de fato.
///
/// O endereço sem `#` (`/gallery/`, o link do README), com barra no fim ou
/// com um estado que não existe é corrigido para a forma certa
/// (`/gallery/#/visao-geral`). O padrão do Flutter empilhava a correção
/// como página nova: o primeiro Voltar voltava para o endereço torto, que
/// mostra a mesma página, e parecia não fazer nada. Aqui, endereço que leva
/// ao mesmo lugar substitui o que está no navegador.
class GalleryAddress extends PlatformRouteInformationProvider {
  /// Cria o endereço, a partir do que o navegador abriu.
  new({required super.initialRouteInformation});

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    final same =
        GalleryRouteParser.locationOf(value.uri) ==
        GalleryRouteParser.locationOf(routeInformation.uri);
    super.routerReportsNewRouteInformation(
      routeInformation,
      type: same && type == RouteInformationReportingType.none
          ? RouteInformationReportingType.neglect
          : type,
    );
  }
}
