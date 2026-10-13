import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/tokens/contrast_row.dart';
import 'package:gallery/src/shell/gallery_page.dart';
import 'package:gallery/src/shell/gallery_section.dart';

/// A tabela de contraste, calculada na hora a partir dos tokens.
///
/// Usa a mesma lista de pares do teste automatizado (`ContrastAudit`): a
/// página não pode dizer uma coisa e o teste outra.
class ContrastPage extends StatefulWidget {
  /// Cria a página de contraste.
  const new({super.key});

  @override
  State<ContrastPage> createState() => _ContrastPageState();
}

class _ContrastPageState extends State<ContrastPage> {
  /// A lista inteira abre sob pedido. Aberta de cara, eram 90 linhas iguais
  /// com "passa" em verde, e o recado já está no aviso do alto. Par
  /// reprovado, se houver, aparece sempre, fora da lista.
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final pairs = ContrastAudit.pairsFor(CajuiTheme.of(context).colors);
    final failing = pairs.where((pair) => !pair.passes).toList();
    return GalleryPage(
      title: 'Contraste',
      lead:
          'Cada par de cores que o app de fato usa, medido pela fórmula da '
          'WCAG 2.2 no tema em vigor. Nada aqui é digitado à mão.',
      sections: [
        _summary(pairs.length, failing.length),
        if (failing.isNotEmpty) _table('Pares abaixo do mínimo', failing),
        _everyPair(pairs),
      ],
    );
  }

  Widget _summary(int total, int failing) {
    final allPass = failing == 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.section),
      child: CajuiNotice(
        intent: allPass ? CajuiNoticeIntent.positive : CajuiNoticeIntent.danger,
        what: allPass
            ? 'Os $total pares passam no nível AA.'
            : '$failing de $total pares estão abaixo do mínimo.',
        meaning: allPass
            ? 'Texto comum pede 4,5:1; texto grande e borda de componente, '
                  '3:1.'
            : 'Ajuste o token na paleta e rode o teste de contraste.',
      ),
    );
  }

  Widget _everyPair(List<ContrastPair> pairs) {
    return GallerySection(
      title: 'Todos os pares',
      description: 'Texto, ação, borda e aviso sobre cada superfície.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CajuiButton(
            label: _all
                ? 'Esconder os ${pairs.length} pares'
                : 'Mostrar os ${pairs.length} pares',
            variant: CajuiButtonVariant.secondary,
            size: CajuiButtonSize.compact,
            onPressed: () => setState(() => _all = !_all),
          ),
          if (_all) ...[
            const SizedBox(height: CajuiSpacing.lg),
            for (final pair in pairs) ContrastRow(pair),
          ],
        ],
      ),
    );
  }

  Widget _table(String title, List<ContrastPair> pairs) {
    return GallerySection(
      title: title,
      child: Column(children: [for (final pair in pairs) ContrastRow(pair)]),
    );
  }
}
