import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/home/home_links.dart';
import 'package:gallery/src/pages/screens/home/home_numbers.dart';
import 'package:gallery/src/pages/screens/shared/common_variants.dart';
import 'package:gallery/src/pages/screens/shared/screen_state_page.dart';
import 'package:gallery/src/pages/screens/shared/screen_tools.dart';
import 'package:gallery/src/pages/screens/shared/screen_variant.dart';

/// O Início, em todos os estados da matriz de telas, montado como o app o
/// monta: o esqueleto de tela do design system com a rolagem em
/// profundidade e a entrada cinematográfica ligadas.
class HomePage extends StatelessWidget {
  /// Cria a página do Início, aberta no estado [initialIndex].
  const new({this.initialIndex = 0, super.key});

  /// O estado aberto ao entrar: a vitrine de estados abre direto no que
  /// foi tocado.
  final int initialIndex;

  /// O nome da tela, o mesmo do menu.
  static const title = 'Início';

  /// O papel da tela no app.
  static const lead =
      'O mês da planilha de relance e as portas para o resto do app. '
      'Responde primeiro se o mês fecha — a sobra, ou quanto falta —, '
      'com um aviso por vez, e só quando há o que fazer.';

  static const _month = 'Outubro';

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
    _ready(
      'Com dados',
      'Outubro andando. A sobra vem na frente do carrossel; arraste de '
          'lado para o que entra, o que sai do bolso e o vale.',
      HomeNumbers.closing(),
    ),
    _party(),
    CommonVariants.loading('Início'),
    CommonVariants.serverError('Início'),
    CommonVariants.offline(_month, _cached()),
    _firstUse(),
    _noIncome(),
    _short(),
    _toReview(),
    _readOnly(),
    _webEmpty(),
  ];

  static ScreenVariant _party() => _ready(
    'Mês no verde, primeira vez',
    'Escolha 5 do dono: na primeira vez em que o mês fecha, a sobra faz '
        'festa ao aparecer. Nas outras, só o brilho calmo.',
    HomeNumbers.closing(party: true),
  );

  static List<Widget> _cached() => [
    HomeNumbers.carousel(HomeNumbers.closing()),
    const SizedBox(height: CajuiSpacing.xl),
    ...HomeLinks.of(),
  ];

  /// O Início com os números [pages] no carrossel, [notice] acima deles e
  /// as portas embaixo.
  static ScreenVariant _ready(
    String label,
    String note,
    List<Widget> pages, {
    Widget? notice,
    List<Widget>? links,
    bool readOnly = false,
  }) => ScreenVariant(
    label: label,
    note: note,
    builder: (_) => CajuiScreen(
      title: _month,
      trailing: ScreenTools(readOnly: readOnly, settings: true),
      footer: readOnly ? null : _newEntry(),
      depth: true,
      cinematic: true,
      replayKey: _month,
      children: [
        ?notice,
        if (notice != null) const SizedBox(height: CajuiSpacing.lg),
        HomeNumbers.carousel(pages),
        const SizedBox(height: CajuiSpacing.xl),
        ...(links ?? HomeLinks.of()),
      ],
    ),
  );

  static Widget _newEntry() => CajuiButton(
    label: 'Novo lançamento',
    icon: CajuiIconData.plus,
    expand: true,
    onPressed: () {},
  );

  static ScreenVariant _firstUse() => _ready(
    'Primeiro uso',
    'RN-1050: o plano não é obrigatório. Sem ele, o número é o que já '
        'saiu, e a frase diz onde se cadastra o resto.',
    HomeNumbers.noPlan(),
    links: HomeLinks.of(
      income: 0,
      outOfPocket: HomeNumbers.firstSpent,
      entries: 3,
      voucher: false,
      debts: false,
    ),
  );

  static ScreenVariant _noIncome() => _ready(
    'Sem renda cadastrada',
    'RN-604: proporção sobre renda zero é indefinida. O cartão mostra um '
        'travessão, nunca 0% nem infinito.',
    HomeNumbers.noIncome(),
    links: HomeLinks.of(income: 0),
  );

  static ScreenVariant _short() => _ready(
    'Mês que não fecha',
    'RN-1060: a falta entra sem brilho e sem alarme, e a frase diz o que '
        'fazer. O tom segue a escolha barro × vermelho.',
    HomeNumbers.short(),
    links: HomeLinks.of(outOfPocket: HomeNumbers.tightOutOfPocket),
  );

  static ScreenVariant _toReview() => _ready(
    'Para conferir',
    'Comprovantes recebidos e ainda não confirmados: só entram nos números '
        'depois da conferência.',
    HomeNumbers.closing(),
    notice: CajuiNotice(
      intent: CajuiNoticeIntent.info,
      what: '2 comprovantes esperando conferência.',
      meaning: 'Só entra nos números depois que você confirmar.',
      primaryAction: CajuiNoticeAction(
        label: 'Conferir agora',
        onPressed: () {},
      ),
    ),
  );

  static ScreenVariant _readOnly() => _ready(
    'Consulta pela web',
    'ADR-013: no computador o Início é só leitura. Sem câmera, sem galeria '
        'e sem "Novo lançamento": lançar é no celular.',
    HomeNumbers.closing(),
    readOnly: true,
  );

  static ScreenVariant _webEmpty() => ScreenVariant(
    label: 'Consulta pela web, sem dados',
    note:
        'ADR-020: o celular manda os lançamentos sozinho. Se ainda não '
        'chegou nada, a web diz isso e oferece reler o servidor.',
    builder: (_) => CajuiScreen(
      title: 'Início',
      trailing: const ScreenTools(readOnly: true, settings: true),
      children: [
        CajuiEmptyState(
          illustration: const CajuiHeroFruit(),
          title: 'Ainda não chegou nada deste mês',
          message:
              'O celular manda os lançamentos sozinho assim que você lança. '
              'Se acabou de lançar, atualize.',
          action: CajuiNoticeAction(label: 'Atualizar', onPressed: () {}),
        ),
      ],
    ),
  );
}
