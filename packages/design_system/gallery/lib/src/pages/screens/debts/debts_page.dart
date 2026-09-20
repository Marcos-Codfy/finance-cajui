import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/shared/common_variants.dart';
import 'package:gallery/src/pages/screens/shared/mock_screen.dart';
import 'package:gallery/src/pages/screens/shared/screen_state_page.dart';
import 'package:gallery/src/pages/screens/shared/screen_variant.dart';
import 'package:gallery/src/pages/screens/shared/stat_card.dart';

/// As dívidas, em todos os estados da matriz de telas.
///
/// As duas do exemplo somam os R$ 362,00 de dívidas do mês da especificação.
class DebtsPage extends StatelessWidget {
  /// Cria a página das dívidas.
  const new({super.key});

  static const _title = 'Dívidas';
  static const _gap = SizedBox(height: CajuiSpacing.lg);

  @override
  Widget build(BuildContext context) {
    return ScreenStatePage(
      title: 'Dívidas',
      lead:
          'Dívida à vista, sem susto e sem sermão: quanto sai por mês, quanto '
          'falta e quando acaba. A previsão é sempre dita como previsão.',
      variants: [
        _variant('Com dívidas', 'RN-531: a quitação é projeção.', _debts()),
        CommonVariants.loading(_title),
        CommonVariants.serverError(_title),
        CommonVariants.offline(_title, _debts()),
        _empty(),
        _installmentDue(),
        _paidOff(),
      ],
    );
  }

  ScreenVariant _variant(String label, String note, List<Widget> children) {
    return ScreenVariant(
      label: label,
      note: note,
      builder: (_) => MockScreen(title: _title, children: children),
    );
  }

  List<Widget> _debts() => [
    const StatCard(
      label: 'Sai por mês em dívidas',
      cents: 36200,
      large: true,
      caption: '11% da renda de setembro',
    ),
    _debt('Empréstimo pessoal', 21200, paid: 8, total: 24, ends: 'jan. 2028'),
    _debt('Geladeira', 15000, paid: 4, total: 10, ends: 'mar. 2027'),
  ];

  Widget _debt(
    String name,
    int installment, {
    required int paid,
    required int total,
    required String ends,
  }) {
    return StatCard(
      label: name,
      cents: installment,
      meter: paid / total,
      caption: '$paid de $total parcelas · no ritmo atual, quita em $ends',
    );
  }

  ScreenVariant _empty() => _variant(
    'Vazia',
    'Sem dívida cadastrada. Não é erro, e a tela não comemora nem cobra.',
    const [
      CajuiEmptyState(
        title: 'Nenhuma dívida cadastrada',
        message:
            'Se aparecer alguma — empréstimo, parcelamento, fatura que '
            'ficou para depois —, é aqui que ela fica à vista.',
      ),
    ],
  );

  ScreenVariant _installmentDue() => _variant(
    'Com parcela em aberto',
    'A parcela venceu e não há confirmação de pagamento.',
    [
      CajuiNotice(
        what: 'A parcela de setembro do empréstimo está em aberto.',
        meaning:
            'Venceu em 10/09. Se já foi paga, é só confirmar; se não, ela '
            'continua contando como compromisso do mês.',
        primaryAction: CajuiNoticeAction(label: 'Já paguei', onPressed: () {}),
        secondaryAction: CajuiNoticeAction(
          label: 'Ainda não',
          onPressed: () {},
        ),
      ),
      _gap,
      ..._debts(),
    ],
  );

  /// O marco: uma das poucas telas que comemoram. Uma vez só, sem confete.
  ScreenVariant _paidOff() => _variant(
    'Dívida quitada (marco)',
    'Conquista: ícone-herói, som de conquista e o efeito no mês seguinte.',
    [
      CajuiEmptyState(
        illustration: const CajuiHeroFruit(size: 140),
        title: 'Geladeira quitada',
        message:
            'Foram 10 parcelas. A partir de abril, '
            '${BrlFormatter.format(15000)} voltam para o seu mês.',
        action: CajuiNoticeAction(label: 'Ver o mês novo', onPressed: () {}),
      ),
      _gap,
      // Março de 2027, o mês da última parcela da geladeira: o empréstimo,
      // que estava em 8 de 24 em setembro, chegou a 14.
      _debt('Empréstimo pessoal', 21200, paid: 14, total: 24, ends: 'jan. 2028'),
    ],
  );
}
