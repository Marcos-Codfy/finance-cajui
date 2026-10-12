import 'package:gallery/src/shell/gallery_destination.dart';

/// Onde a gallery está: a página e, numa tela do app, o estado aberto.
///
/// É o que vai no endereço (`/gallery/#/inicio?estado=sem-rede`): dá para
/// mandar a alguém o link de uma tela num estado só, e o Voltar do
/// navegador volta para a página de antes.
typedef GalleryLocation = ({GalleryDestination page, String? state});
