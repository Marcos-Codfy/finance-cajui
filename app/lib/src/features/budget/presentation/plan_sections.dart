import 'package:cajui/src/features/budget/application/month_setup.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// As três seções da tela do plano: renda e dívidas, contas fixas, gastos
/// variáveis. Cada linha abre a edição do que mostra.
abstract final class PlanSections {
  static const _gap = SizedBox(height: CajuiSpacing.md);

  static String _brl(Money amount) => BrlFormatter.format(amount.cents);

  /// Renda e dívidas.
  static List<Widget> money(
    MonthSetup setup,
    VoidCallback onIncome,
    VoidCallback onDebts,
  ) => [
    const _SectionTitle('Renda e dívidas'),
    CajuiListRow(
      title: 'Renda em dinheiro',
      subtitle: 'O vale fica de fora: é outra moeda',
      trailing: CajuiAmountText(setup.cashIncome.cents),
      semanticLabel: 'Renda em dinheiro, ${_brl(setup.cashIncome)}, editar',
      onPressed: onIncome,
    ),
    CajuiListRow(
      title: 'Parcelas de dívida',
      subtitle: 'Empréstimo e financiamento, por mês',
      trailing: CajuiAmountText(setup.debtInstallments.cents),
      semanticLabel:
          'Parcelas de dívida, ${_brl(setup.debtInstallments)}, editar',
      onPressed: onDebts,
    ),
  ];

  /// As contas fixas, por dia de vencimento.
  static List<Widget> fixed(
    MonthSetup setup,
    void Function([FixedExpense? existing]) onEdit,
  ) {
    final byDueDay = [...setup.fixedExpenses]
      ..sort((a, b) => a.dueDay.compareTo(b.dueDay));
    return [
      const _SectionTitle('Contas fixas'),
      for (final expense in byDueDay)
        CajuiListRow(
          title: expense.name,
          subtitle: 'vence dia ${expense.dueDay}',
          trailing: CajuiAmountText(expense.amount.cents),
          semanticLabel: '${expense.name}, ${_brl(expense.amount)}, editar',
          onPressed: () => onEdit(expense),
        ),
      _gap,
      CajuiButton(
        label: 'Adicionar conta fixa',
        variant: CajuiButtonVariant.secondary,
        icon: CajuiIconData.plus,
        onPressed: onEdit,
      ),
    ];
  }

  /// As faixas dos variáveis. O subtítulo lembra a regra que dá o tom do
  /// produto: o plano conta pelo máximo.
  static List<Widget> variable(
    LedgerBook book,
    void Function([VariableBudget? existing]) onEdit,
  ) => [
    const _SectionTitle('Gastos variáveis'),
    for (final budget in book.setup.variableBudgets)
      CajuiListRow(
        title: book.categoryOf(budget.categoryId).name,
        subtitle:
            'de ${_brl(budget.range.min)} a ${_brl(budget.range.max)} · '
            'conta pelo máximo',
        trailing: const CajuiIcon(CajuiIconData.chevronRight),
        semanticLabel: '${book.categoryOf(budget.categoryId).name}, editar',
        onPressed: () => onEdit(budget),
      ),
    _gap,
    CajuiButton(
      label: 'Adicionar gasto variável',
      variant: CajuiButtonVariant.secondary,
      icon: CajuiIconData.plus,
      onPressed: onEdit,
    ),
  ];
}

class _SectionTitle extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        top: CajuiSpacing.section,
        bottom: CajuiSpacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Text(text, style: theme.typography.title),
      ),
    );
  }
}
