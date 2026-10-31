import 'package:cajui/src/core/navigation/coordinator_access.dart';
import 'package:cajui/src/features/budget/presentation/budget_coordinator.dart';
import 'package:cajui/src/features/cards/application/statement_view.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// Uma fatura na tela: o total, de que ele é feito, as parcelas com o que
/// ainda está comprometido, e o pagamento.
class StatementSection extends StatefulWidget {
  /// Cria a seção da fatura [view].
  const new({
    required this.view,
    required this.book,
    required this.title,
    required this.onSettle,
    super.key,
  });

  /// A fatura.
  final StatementView view;

  /// O livro, de onde saem os nomes das categorias.
  final LedgerBook book;

  /// "Fatura fechada · vence em 5 de outubro".
  final String title;

  /// Registra o pagamento do valor dado.
  final ValueChanged<Money> onSettle;

  @override
  State<StatementSection> createState() => _StatementSectionState();
}

class _StatementSectionState extends State<StatementSection> {
  /// O total que o banco cobrou, quando a pessoa informou para conferir.
  Money? _bankTotal;

  StatementView get _view => widget.view;

  String _brl(Money amount) => BrlFormatter.format(amount.cents);

  Future<void> _pay() async {
    final cents = await context
        .coordinator(budgetCoordinatorProvider)
        .askAmount(
          title: 'Pagamento da fatura',
          label: 'Quanto foi pago',
          explanation:
              'Pagar a fatura não é uma despesa nova: as compras já contaram '
              'quando foram feitas. Aqui o Cajui só registra que a fatura foi '
              'paga.',
          initialCents: _view.openBalance.cents,
        );
    if (cents != null && cents > 0) widget.onSettle(Money.fromCents(cents));
  }

  Future<void> _compare() async {
    final cents = await context
        .coordinator(budgetCoordinatorProvider)
        .askAmount(
          title: 'Conferir com o banco',
          label: 'Total da fatura no app do banco',
          explanation:
              'Se o total do banco for maior, a diferença aparece como valor '
              'ainda não identificado — um sinal de compra que falta lançar. O '
              'Cajui nunca cria uma despesa de ajuste para fechar a conta.',
        );
    if (cents != null) setState(() => _bankTotal = Money.fromCents(cents));
  }

  @override
  Widget build(BuildContext context) {
    final statement = _view.statement;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CajuiStatCard(
          label: widget.title,
          cents: statement.total.cents,
          caption:
              'compras à vista ${_brl(statement.purchases)} · parcelas '
              '${_brl(statement.installments)}',
        ),
        ..._composition(),
        ..._installments(),
        ?_difference(),
        const SizedBox(height: CajuiSpacing.md),
        ..._payment(),
        const SizedBox(height: CajuiSpacing.section),
      ],
    );
  }

  /// De que a fatura é feita, por categoria (RN-331).
  List<Widget> _composition() => [
    for (final MapEntry(key: id, value: amount)
        in _view.statement.purchasesByCategory.entries)
      CajuiListRow(
        title: widget.book.categoryOf(id).name,
        subtitle: 'compras à vista nesta fatura',
        trailing: CajuiAmountText(amount.cents),
      ),
  ];

  /// A parcela nunca aparece sem o total ainda comprometido (RN-313).
  List<Widget> _installments() {
    final month = _view.cycle.dueMonth;
    return [
      for (final entry in _view.parceled)
        if (entry.installmentPlan case final plan?)
          CajuiListRow(
            title: entry.description,
            subtitle:
                'parcela ${plan.installmentDueIn(month)!.number} de '
                '${plan.count} · ainda comprometido '
                '${_brl(plan.committedFrom(month))}',
            trailing: CajuiAmountText(
              plan.installmentDueIn(month)!.amount.cents,
            ),
          ),
    ];
  }

  /// A diferença para o total do banco (RN-332 e RN-344).
  Widget? _difference() {
    final bank = _bankTotal;
    if (bank == null) return null;
    final unidentified = _view.statement.unidentifiedGiven(bank);
    if (unidentified.isZero) {
      return const CajuiNotice(
        intent: CajuiNoticeIntent.positive,
        what: 'O total bate com o do banco.',
      );
    }
    return CajuiNotice(
      intent: CajuiNoticeIntent.info,
      what: unidentified.isPositive
          ? '${_brl(unidentified)} ainda não identificados.'
          : 'O banco cobrou ${_brl(-unidentified)} a menos que o calculado.',
      meaning: unidentified.isPositive
          ? 'Pode ser uma compra que falta lançar, ou juros e tarifa.'
          : 'Pode haver um estorno que ainda não foi lançado.',
    );
  }

  List<Widget> _payment() {
    final theme = CajuiTheme.of(context);
    final paid = _view.paid;
    return [
      if (paid.isPositive)
        Text(
          _view.openBalance.isZero
              ? 'Paga: ${_brl(paid)}.'
              : 'Pago ${_brl(paid)}. Em aberto: ${_brl(_view.openBalance)}.',
          style: theme.typography.label.copyWith(
            color: theme.colors.text.muted,
          ),
        ),
      if (_view.openBalance.isPositive)
        CajuiButton(label: 'Registrar pagamento', onPressed: _pay),
      CajuiButton(
        label: 'Conferir com o banco',
        variant: CajuiButtonVariant.ghost,
        onPressed: _compare,
      ),
    ];
  }
}
