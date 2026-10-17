import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/shell/gallery_section.dart';
import 'package:gallery/src/shell/gallery_specimen.dart';
import 'package:gallery/src/shell/gallery_specimens.dart';

/// As ilustrações leves do Cerrado, cada uma no vazio em que o app a usa.
class CerradoSection extends StatelessWidget {
  /// Cria a seção.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const GallerySection(
      title: 'Ilustrações do Cerrado',
      description:
          'A versão calma do ícone-herói para os vazios das listas: '
          'chapadas, sobre um disco do fundo afundado, pintadas só com os '
          'tokens do tema. Balançam devagar ao vento no movimento completo; '
          'no leve e no reduzido ficam paradas, de pé.',
      child: GallerySpecimens(children: _specimens),
    );
  }

  static const _specimens = [
    _Specimen(
      CajuiCerrado.cashew,
      'Cajuí · fatura sem compras',
      'Nenhuma compra neste cartão',
      'Ao lançar uma despesa, escolha este cartão.',
    ),
    _Specimen(
      CajuiCerrado.leaf,
      'Folha · sem cartão',
      'Nenhum cartão ainda',
      'O Cajui só precisa do nome e dos dias do cartão.',
    ),
    _Specimen(
      CajuiCerrado.ipe,
      'Ipê · sem dívida',
      'Nenhuma dívida cadastrada',
      'Se aparecer alguma, é aqui que ela fica à vista.',
    ),
  ];
}

/// Um vazio com a ilustração [kind], como o app o mostra.
class _Specimen extends StatelessWidget {
  const new(this.kind, this.state, this.title, this.message);

  final CajuiCerrado kind;
  final String state;
  final String title;
  final String message;

  /// O nome do valor na API, que o exemplar mostra ao lado do estado.
  String get _api => 'CajuiCerrado.${kind.name}';

  @override
  Widget build(BuildContext context) => GallerySpecimen(
    state: state,
    token: _api,
    width: 440,
    child: CajuiEmptyState(
      illustration: CajuiCerradoArt(kind),
      title: title,
      message: message,
    ),
  );
}
