import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/shared/common_variants.dart';
import 'package:gallery/src/pages/screens/shared/mock_screen.dart';
import 'package:gallery/src/pages/screens/shared/screen_state_page.dart';
import 'package:gallery/src/pages/screens/shared/screen_variant.dart';
import 'package:gallery/src/pages/screens/shared/stat_card.dart';

/// O fechamento do mês, em todos os estados da matriz de telas.
class ClosingPage extends StatelessWidget {
  /// Cria a página do fechamento, aberta no estado [initialIndex].
  const new({this.initialIndex = 0, super.key});

  /// O estado aberto ao entrar: a vitrine de estados abre direto no que
  /// foi tocado.
  final int initialIndex;

  /// O nome da tela, o mesmo do menu.
  static const title = 'Fechamento do mês';

  /// O papel da tela no app.
  static const lead =
      'O retrato de um mês encerrado. É a tela que dá a notícia — boa ou '
      'ruim — e por isso é onde o tom de voz mais importa.';

  static const _screenTitle = 'Fechamento de setembro';
  static const _gap = SizedBox(height: CajuiSpacing.lg);

  static String _brl(int cents) => BrlFormatter.format(cents);

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
    _withLeftover(),
    CommonVariants.loading(_screenTitle),
    CommonVariants.serverError(_screenTitle),
    CommonVariants.offline(_screenTitle, _summary(leftover: 55800)),
    _tooEarly(),
    _openItems(),
    shortfall(),
    _closed(),
    _revised(),
  ];

  static ScreenVariant _variant(
    String label,
    String note,
    List<Widget> children, {
    String? action,
    String? overline,
  }) {
    return ScreenVariant(
      label: label,
      note: note,
      builder: (_) => MockScreen(
        title: _screenTitle,
        overline: overline,
        footer: action == null
            ? null
            : CajuiButton(label: action, expand: true, onPressed: () {}),
        children: children,
      ),
    );
  }

  /// O resultado do mês e de onde ele veio. Sobra e falta usam o mesmo
  /// cartão: muda o rótulo, o sinal e o tom — nunca o tamanho do alarme.
  static List<Widget> _summary({
    required int leftover,
    int variable = 98000,
  }) => [
    StatCard(
      label: leftover < 0 ? 'Faltou em setembro' : 'Sobrou em setembro',
      cents: leftover,
      large: true,
      tone: leftover < 0 ? CajuiAmountTone.shortfall : CajuiAmountTone.positive,
    ),
    CajuiCard(
      child: Column(
        children: [
          _line('Renda', 320000),
          _line('Fixos', -130000),
          _line('Variáveis', -variable),
          _line('Dívidas', -36200),
        ],
      ),
    ),
    _gap,
    const StatCard(
      label: 'Vale alimentação que sobrou',
      cents: 3840,
      tone: CajuiAmountTone.accent,
      sunken: true,
      caption: 'Acumula para outubro. Não entra na conta do dinheiro.',
    ),
  ];

  static Widget _line(String label, int cents) => CajuiListRow(
    title: label,
    trailing: CajuiAmountText(cents, tone: CajuiAmountTone.muted),
  );

  static CajuiNotice _notice(
    CajuiNoticeIntent intent,
    String what,
    String meaning, {
    String? action,
    String? secondary,
  }) {
    return CajuiNotice(
      intent: intent,
      what: what,
      meaning: meaning,
      primaryAction: action == null
          ? null
          : CajuiNoticeAction(label: action, onPressed: () {}),
      secondaryAction: secondary == null
          ? null
          : CajuiNoticeAction(label: secondary, onPressed: () {}),
    );
  }

  static ScreenVariant _withLeftover() => _variant(
    'Com sobra',
    'Pronto para fechar, tudo conferido.',
    _summary(leftover: 55800),
    action: 'Fechar setembro',
  );

  static ScreenVariant _tooEarly() => _variant(
    'Mês em curso',
    'E-BUDG-02: fechar um mês que ainda não terminou.',
    [
      _notice(
        CajuiNoticeIntent.info,
        'Setembro ainda não terminou.',
        'Dá para fechar a partir de 01/10. Até lá, estes números são a '
            'projeção do mês, com os variáveis pelo pior caso.',
      ),
      _gap,
      ..._summary(leftover: 55800),
    ],
  );

  static ScreenVariant _openItems() => _variant(
    'Com itens em aberto',
    'Dá para fechar assim mesmo: o que entrar depois vira revisão (RN-441).',
    [
      _notice(
        CajuiNoticeIntent.attention,
        '2 coisas em aberto antes de fechar.',
        'Um comprovante esperando conferência e a parcela do empréstimo sem '
            'confirmação de pagamento.',
        action: 'Resolver agora',
        secondary: 'Fechar mesmo assim',
      ),
      _gap,
      ..._summary(leftover: 55800),
    ],
  );

  /// O fechamento com falta. É público porque a página de comparação das
  /// duas versões da falta mostra exatamente esta tela, lado a lado.
  static ScreenVariant shortfall() => _variant(
    'Com falta',
    'RN-443: a falta é informada; o que fazer com ela é decisão de quem usa.',
    [
      ..._summary(leftover: -14200, variable: 168000),
      _gap,
      _notice(
        CajuiNoticeIntent.info,
        'Setembro fechou ${_brl(14200)} acima da renda.',
        'Essa falta não vira dívida nem é descontada de outubro por conta '
            'própria. A maior parte veio do conserto do carro, fora do '
            'padrão do mês.',
        action: 'Ver de onde veio',
      ),
    ],
    action: 'Fechar setembro',
  );

  static ScreenVariant _closed() => _variant(
    'Fechado',
    'RN-440: retrato imutável. Mudar uma faixa em outubro não mexe aqui.',
    [
      _notice(
        CajuiNoticeIntent.positive,
        'Setembro está fechado.',
        'Sobraram ${_brl(9600)} a mais que em agosto.',
      ),
      _gap,
      ..._summary(leftover: 55800),
    ],
  );

  static ScreenVariant _revised() => _variant(
    'Revisado',
    'RN-441: lançamento tardio gera revisão; a versão anterior é preservada.',
    [
      _notice(
        CajuiNoticeIntent.info,
        'Setembro foi revisado em 03/10.',
        'Entraram ${_brl(4200)} em transporte, lançados depois do '
            'fechamento. A versão anterior continua guardada.',
        action: 'Ver a versão anterior',
      ),
      _gap,
      ..._summary(leftover: 51600, variable: 102200),
    ],
    overline: 'Revisão 2',
  );
}
