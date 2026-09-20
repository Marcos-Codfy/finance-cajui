import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/dashboard/dashboard_blocks.dart';
import 'package:gallery/src/pages/screens/shared/common_variants.dart';
import 'package:gallery/src/pages/screens/shared/mock_screen.dart';
import 'package:gallery/src/pages/screens/shared/screen_state_page.dart';
import 'package:gallery/src/pages/screens/shared/screen_variant.dart';
import 'package:gallery/src/pages/screens/shared/stat_card.dart';

/// O painel, em todos os estados da matriz de telas.
class DashboardPage extends StatelessWidget {
  /// Cria a página do painel.
  const new({super.key});

  static const _title = 'Setembro';
  static const _overline = 'Semana 3 · 15 a 21';

  @override
  Widget build(BuildContext context) {
    return ScreenStatePage(
      title: 'Painel',
      lead:
          'A primeira tela. Responde uma pergunta antes de qualquer outra: '
          'quanto dá para gastar nesta semana.',
      variants: [
        _variant('Com dados', 'O mês andando normalmente.', [
          ...DashboardBlocks.regular(),
        ]),
        CommonVariants.loading(_title),
        CommonVariants.serverError(_title),
        CommonVariants.offline(_title, DashboardBlocks.regular()),
        _firstUse(),
        _noIncome(),
        _variableSpent(),
        _splitWeek(),
        _toReview(),
        _readOnly(),
      ],
    );
  }

  ScreenVariant _variant(
    String label,
    String note,
    List<Widget> children, {
    String overline = _overline,
    bool canAdd = true,
  }) {
    return ScreenVariant(
      label: label,
      note: note,
      builder: (_) => MockScreen(
        title: _title,
        overline: overline,
        footer: canAdd ? _addButton() : null,
        children: children,
      ),
    );
  }

  Widget _addButton() => CajuiButton(
    label: 'Novo lançamento',
    icon: CajuiIconData.plus,
    expand: true,
    onPressed: () {},
  );

  ScreenVariant _firstUse() => _variant(
    'Primeiro uso',
    'Nada cadastrado ainda. A tela explica o que vai aparecer e dá o passo.',
    [
      CajuiEmptyState(
        illustration: const CajuiHeroFruit(size: 120),
        title: 'Seu mês começa aqui',
        message:
            'Com a renda e as contas fixas, o Cajui já diz quanto dá para '
            'gastar por semana. Leva uns cinco minutos.',
        action: CajuiNoticeAction(label: 'Começar', onPressed: () {}),
      ),
    ],
    canAdd: false,
  );

  ScreenVariant _noIncome() => _variant(
    'Sem renda cadastrada',
    'RN-604: proporção sobre renda zero é indefinida. Nunca 0% nem infinito.',
    [
      CajuiNotice(
        what: 'Falta a renda de setembro.',
        meaning:
            'Sem ela não dá para dizer quanto sobra nem quanto dá para '
            'gastar. Os lançamentos continuam valendo.',
        primaryAction: CajuiNoticeAction(
          label: 'Cadastrar a renda',
          onPressed: () {},
        ),
      ),
      const SizedBox(height: CajuiSpacing.lg),
      const StatCard(label: 'Dá para gastar esta semana', large: true),
      DashboardBlocks.leftover(cents: null),
      DashboardBlocks.voucher(),
    ],
  );

  ScreenVariant _variableSpent() => _variant(
    'Variável esgotado',
    'RN-645: limite da semana zero, e quanto passou do plano, em tom neutro.',
    [
      StatCard(
        label: 'Dá para gastar esta semana',
        cents: 0,
        large: true,
        meter: 1.04,
        caption:
            'O variável do mês já passou ${BrlFormatter.format(4000)} do '
            'plano',
      ),
      CajuiNotice(
        intent: CajuiNoticeIntent.info,
        what: 'Dá para cobrir sem mexer nos fixos.',
        meaning: 'Há folga em Lazer e em Transporte para remanejar.',
        primaryAction: CajuiNoticeAction(
          label: 'Ver os ajustes',
          onPressed: () {},
        ),
      ),
      const SizedBox(height: CajuiSpacing.lg),
      DashboardBlocks.voucher(),
    ],
  );

  ScreenVariant _splitWeek() => _variant(
    'Semana partida',
    'RN-644: a semana da virada vale em cada mês só pelos dias que tem nele.',
    [
      DashboardBlocks.week(limit: 12000, spent: 3150),
      DashboardBlocks.leftover(),
      DashboardBlocks.voucher(),
    ],
    overline: 'Semana 5 · 28 a 30 · 3 dias em setembro',
  );

  ScreenVariant _toReview() => _variant(
    'Com capturas para conferir',
    'Comprovantes recebidos e ainda não confirmados. Não contam no limite.',
    [
      CajuiNotice(
        intent: CajuiNoticeIntent.info,
        what: '2 comprovantes esperando conferência.',
        meaning: 'Só entram nos números depois que você confirmar.',
        primaryAction: CajuiNoticeAction(
          label: 'Conferir agora',
          onPressed: () {},
        ),
      ),
      const SizedBox(height: CajuiSpacing.lg),
      ...DashboardBlocks.regular(),
    ],
  );

  ScreenVariant _readOnly() => _variant(
    'Modo consulta (web)',
    'No computador o painel é só leitura: lançar e ler comprovante é no '
        'celular.',
    [
      const CajuiNotice(
        intent: CajuiNoticeIntent.info,
        what: 'Você está no modo consulta.',
        meaning:
            'Aqui dá para ver tudo e conversar com o assistente. Para '
            'lançar, use o app no celular.',
      ),
      const SizedBox(height: CajuiSpacing.lg),
      ...DashboardBlocks.regular(),
    ],
    canAdd: false,
  );
}
