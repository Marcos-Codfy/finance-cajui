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
  /// Cria a página das dívidas, aberta no estado [initialIndex].
  const new({this.initialIndex = 0, super.key});

  /// O estado aberto ao entrar: a vitrine de estados abre direto no que
  /// foi tocado.
  final int initialIndex;

  /// O nome da tela, o mesmo do menu e o do alto da tela no app.
  static const title = 'Dívidas';

  /// O papel da tela no app.
  static const lead =
      'Dívida à vista, sem susto e sem sermão: quanto sai por mês, quanto '
      'falta e quando acaba. A previsão é sempre dita como previsão.';

  static const _gap = SizedBox(height: CajuiSpacing.lg);

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
    _variant('Com dívidas', 'RN-531: a quitação é projeção.', _debts()),
    CommonVariants.loading(title),
    CommonVariants.serverError(title),
    CommonVariants.offline(title, _debts()),
    _empty(),
    _installmentDue(),
    _paidOff(),
  ];

  static ScreenVariant _variant(
    String label,
    String note,
    List<Widget> children,
  ) {
    return ScreenVariant(
      label: label,
      note: note,
      builder: (_) => MockScreen(title: title, children: children),
    );
  }

  static List<Widget> _debts() => [
    const StatCard(
      label: 'Sai por mês em dívidas',
      cents: 36200,
      large: true,
      caption: '11% da renda de setembro',
    ),
    _debt('Empréstimo pessoal', 21200, paid: 8, total: 24, ends: 'jan. 2028'),
    _debt('Geladeira', 15000, paid: 4, total: 10, ends: 'mar. 2027'),
  ];

  static Widget _debt(
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

  static ScreenVariant _empty() => _variant(
    'Vazia',
    'Sem dívida cadastrada. Não é erro, e a tela não comemora nem cobra: '
        'o ipê em flor só diz, em silêncio, que é boa notícia.',
    const [
      CajuiEmptyState(
        illustration: CajuiCerradoArt(CajuiCerrado.ipe),
        title: 'Nenhuma dívida cadastrada',
        message:
            'Se aparecer alguma — empréstimo, parcelamento, fatura que '
            'ficou para depois —, é aqui que ela fica à vista.',
      ),
    ],
  );

  static ScreenVariant _installmentDue() => _variant(
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
  static ScreenVariant _paidOff() => _variant(
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
      _debt(
        'Empréstimo pessoal',
        21200,
        paid: 14,
        total: 24,
        ends: 'jan. 2028',
      ),
    ],
  );
}
