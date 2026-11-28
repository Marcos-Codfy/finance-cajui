import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/entries/entries_parts.dart';
import 'package:gallery/src/pages/screens/shared/common_variants.dart';
import 'package:gallery/src/pages/screens/shared/mock_screen.dart';
import 'package:gallery/src/pages/screens/shared/screen_state_page.dart';
import 'package:gallery/src/pages/screens/shared/screen_variant.dart';

/// Os lançamentos do mês, em todos os estados da matriz de telas.
///
/// Os valores são inventados e fecham entre si: R$ 192,30 em dinheiro e
/// R$ 30,00 no vale, a soma das linhas por moeda.
class EntriesPage extends StatelessWidget {
  /// Cria a página dos lançamentos, aberta no estado [initialIndex].
  const new({this.initialIndex = 0, super.key});

  /// O estado aberto ao entrar: a vitrine de estados abre direto no que
  /// foi tocado.
  final int initialIndex;

  /// O nome da tela, o mesmo do menu e o do alto da tela no app.
  static const title = 'Lançamentos';

  /// O papel da tela no app.
  static const lead =
      'A lista do mês é o assunto da tela e aparece logo: o resumo do que já '
      'foi gasto é baixo, a busca fica atrás da lupa e os atalhos filtram '
      'com um toque. O rodapé é uma linha só: "Gastei", a foto e a galeria.';

  static const _gap = SizedBox(height: CajuiSpacing.lg);

  /// O dinheiro e o vale do mês do exemplo.
  static const _cash = 19230;
  static const _voucher = 3000;

  @override
  Widget build(BuildContext context) {
    return ScreenStatePage(
      title: title,
      lead: lead,
      variants: variants(),
      initialIndex: initialIndex,
    );
  }

  /// Os estados, na ordem do seletor. Ficam fora do `build` para que a
  /// vitrine de estados mostre exatamente os mesmos, lado a lado.
  static List<ScreenVariant> variants() => [
    _list(),
    _search(),
    _shortcut(),
    _noMatch(),
    _empty(),
    CommonVariants.loading(title),
  ];

  static ScreenVariant _list() => _variant(
    'Lista do mês',
    'O já gasto por moeda, nunca somado (RN-111). A lupa e os atalhos '
        'ficam na mesma linha dos filtros.',
    (context) => [
      ..._top(context),
      EntriesParts.filters(),
      _gap,
      ...EntriesParts.rows(EntriesParts.month),
    ],
  );

  static ScreenVariant _search() => _variant(
    'Busca aberta',
    'A lupa abre o campo já com o foco. Aberta ou fechada é estado da '
        'barra, e não do texto: apagar a última letra não fecha a busca.',
    (context) => [
      ..._top(context),
      EntriesParts.search('padaria'),
      _gap,
      ...EntriesParts.rows(EntriesParts.month.take(1).toList()),
    ],
  );

  static ScreenVariant _shortcut() => _variant(
    'Atalho ligado',
    '"Só vale alimentação" mostra também a compra dividida com o Pix: '
        'uma das linhas saiu do vale (RN-204).',
    (context) => [
      ..._top(context),
      EntriesParts.filters(on: 'Só vale alimentação'),
      _gap,
      ...EntriesParts.rows([EntriesParts.month[1]]),
    ],
  );

  static ScreenVariant _noMatch() => _variant(
    'Filtro sem resultado',
    'O mês tem lançamento, mas nenhum passa pelos filtros: o vazio diz '
        'qual filtro tirar, em vez de "nada lançado".',
    (context) => [
      ..._top(context),
      EntriesParts.filters(on: 'Só cartão'),
      _gap,
      CajuiEmptyState(
        title: 'Nenhum lançamento com esses filtros',
        message: 'Tire “Só cartão” para ver mais.',
        action: CajuiNoticeAction(label: 'Tirar os filtros', onPressed: () {}),
      ),
    ],
  );

  /// O mês com as setas e o resumo do já gasto.
  static List<Widget> _top(BuildContext context, {bool spent = true}) => [
    EntriesParts.stepper(context, 'setembro de 2026'),
    const SizedBox(height: CajuiSpacing.sm),
    EntriesParts.spent(
      context,
      cash: spent ? _cash : 0,
      voucher: spent ? _voucher : 0,
    ),
    _gap,
  ];

  static ScreenVariant _empty() => _variant(
    'Nada lançado ainda',
    'O mês de hoje sem nada convida a lançar, e diz por onde.',
    (context) => [
      ..._top(context, spent: false),
      const CajuiEmptyState(
        title: 'Nada lançado ainda',
        message:
            'Fotografe o comprovante, escolha um print ou o PDF de um '
            'extrato da galeria, ou lance o primeiro à mão.',
      ),
    ],
  );

  static ScreenVariant _variant(
    String label,
    String note,
    List<Widget> Function(BuildContext context) children,
  ) => ScreenVariant(
    label: label,
    note: note,
    builder: (context) => MockScreen(
      title: title,
      footer: EntriesParts.footer(),
      children: children(context),
    ),
  );
}
