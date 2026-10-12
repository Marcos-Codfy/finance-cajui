import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/shared/common_variants.dart';
import 'package:gallery/src/pages/screens/shared/mock_screen.dart';
import 'package:gallery/src/pages/screens/shared/screen_state_page.dart';
import 'package:gallery/src/pages/screens/shared/screen_variant.dart';
import 'package:gallery/src/pages/screens/statement/statement_blocks.dart';

/// A fatura do cartão, em todos os estados da matriz de telas.
class StatementPage extends StatelessWidget {
  /// Cria a página da fatura.
  const new({super.key});

  static const _title = 'Fatura de outubro';
  static const _gap = SizedBox(height: CajuiSpacing.lg);

  static String _brl(int cents) => BrlFormatter.format(cents);

  @override
  Widget build(BuildContext context) {
    return ScreenStatePage(
      title: 'Fatura do cartão',
      lead:
          'A fatura é uma visão calculada, nunca uma despesa: cada compra já '
          'contou no mês em que foi feita. Pagar a fatura é uma liquidação.',
      variants: [
        _variant(
          'Com dados',
          'RN-330 e RN-331: total calculado, vencimento e composição.',
          StatementBlocks.open(),
          action: 'Registrar o pagamento',
        ),
        CommonVariants.loading(_title),
        CommonVariants.serverError(_title),
        CommonVariants.offline(_title, StatementBlocks.open()),
        _empty(),
        _unidentified(),
        _paid(),
        _partlyPaid(),
        _overpaid(),
      ],
    );
  }

  ScreenVariant _variant(
    String label,
    String note,
    List<Widget> children, {
    String? action,
  }) {
    return ScreenVariant(
      label: label,
      note: note,
      builder: (_) => MockScreen(
        title: _title,
        overline: 'Cartão roxo · ciclo de 29/08 a 28/09',
        footer: action == null
            ? null
            : CajuiButton(label: action, expand: true, onPressed: () {}),
        children: children,
      ),
    );
  }

  Widget _notice(
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

  ScreenVariant _empty() => _variant(
    'Sem compras no ciclo',
    'Fatura zerada não é erro: é um ciclo sem uso do cartão.',
    const [
      CajuiEmptyState(
        title: 'Nenhuma compra neste ciclo',
        message:
            'O que for comprado no cartão até 28/09 aparece aqui, já '
            'separado por bloco.',
      ),
    ],
  );

  ScreenVariant _unidentified() => _variant(
    'Com valor não identificado',
    'RN-332: a diferença vira busca. O app nunca cria despesa de ajuste.',
    [
      _notice(
        CajuiNoticeIntent.attention,
        '${_brl(6000)} ainda não identificados nesta fatura.',
        'A fatura do banco veio em ${_brl(124000)} e os lançamentos somam '
            '${_brl(118000)}. Falta achar o que ficou de fora.',
        action: 'Procurar o que falta',
      ),
      _gap,
      StatementBlocks.total(cents: 118000, caption: 'Calculado pelo Cajui'),
      StatementBlocks.composition(),
    ],
  );

  ScreenVariant _paid() => _variant(
    'Paga',
    'RN-340 e RN-341: liquidação não é despesa, e zera a reserva.',
    [
      _notice(
        CajuiNoticeIntent.positive,
        'Fatura paga em 05/10.',
        'O pagamento não entra como despesa de outubro: cada compra já '
            'contou no mês em que foi feita.',
      ),
      _gap,
      StatementBlocks.total(caption: 'Paga por inteiro'),
      StatementBlocks.composition(),
      StatementBlocks.reserve(cents: 0),
    ],
  );

  ScreenVariant _partlyPaid() => _variant(
    'Paga em parte',
    'RN-342: o saldo vira dívida, com o que foi combinado com o banco.',
    [
      _notice(
        CajuiNoticeIntent.attention,
        'Foram pagos ${_brl(40000)} de ${_brl(124000)}.',
        'Ficaram ${_brl(84000)} em aberto. Para acompanhar esse valor como '
            'dívida, preciso saber o que foi combinado com o banco.',
        action: 'Foi para o rotativo',
        secondary: 'Parcelei a fatura',
      ),
      _gap,
      StatementBlocks.total(caption: 'Pago em parte em 05/10'),
      StatementBlocks.composition(),
    ],
  );

  ScreenVariant _overpaid() => _variant(
    'Pago a mais',
    'RN-344: aceito com aviso; a diferença alimenta a busca da RN-332.',
    [
      _notice(
        CajuiNoticeIntent.info,
        '${_brl(6000)} pagos a mais que o identificado.',
        'Foram pagos ${_brl(124000)} e os lançamentos somam '
            '${_brl(118000)}. Pode ser uma compra que ainda não foi lançada.',
        action: 'Procurar o que falta',
      ),
      _gap,
      StatementBlocks.total(cents: 118000, caption: 'Calculado pelo Cajui'),
      StatementBlocks.composition(),
    ],
  );
}
