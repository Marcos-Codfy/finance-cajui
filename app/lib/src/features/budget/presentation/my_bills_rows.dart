import 'package:cajui/src/features/budget/presentation/tithe_page.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// As linhas de "Minhas contas", na ordem da planilha: o que entra, cada
/// grupo do que sai, as parcelas que vêm das dívidas e o dízimo.
///
/// Só monta as linhas; quem abre cada tela e salva é quem a criou.
final class MyBillsRows {
  /// Cria as linhas de [plan].
  const new({
    required this.plan,
    required this.categories,
    required this.debts,
    required this.readOnly,
    required this.onLine,
    required this.onSalary,
    required this.onVoucher,
    required this.onExtra,
    required this.onTithe,
  });

  /// O plano em vigor.
  final BudgetPlan plan;

  /// As categorias, para o nome de cada linha.
  final Map<String, Category> categories;

  /// As dívidas com saldo, na ordem de quitação.
  final List<Debt> debts;

  /// Consulta pela web: mostra, sem abrir nada.
  final bool readOnly;

  /// Abre uma linha do grupo; `null` cria uma nova.
  final void Function(LineGroup group, BudgetLine? line) onLine;

  /// Abre um salário; `null` cria um novo.
  final void Function(IncomeSource? salary) onSalary;

  /// Abre o vale.
  final VoidCallback onVoucher;

  /// Registra o dinheiro extra do mês.
  final VoidCallback onExtra;

  /// Abre o dízimo.
  final VoidCallback onTithe;

  static String _brl(Money amount) => BrlFormatter.format(amount.cents);

  /// Todas as linhas.
  List<Widget> all() => [
    ..._comesIn(),
    ..._group('Contas fixas', LineGroup.fixedBill),
    ..._group('Assinaturas', LineGroup.subscription),
    ..._group('Dia a dia', LineGroup.dayToDay),
    ..._installments(),
    const CajuiSectionTitle('Dízimo'),
    _row(
      title: plan.titheBasisPoints == 0
          ? 'Não pago dízimo'
          : '${TithePage.labelOf(plan.titheBasisPoints)} da renda em dinheiro',
      subtitle: 'Toque para mudar',
      onPressed: onTithe,
    ),
  ];

  List<Widget> _comesIn() => [
    const CajuiSectionTitle('O que entra'),
    for (final salary in plan.salaries)
      _row(
        title: salary.name,
        subtitle: 'Salário · cai no dia ${salary.expectedDay}',
        amount: salary.expectedAmount,
        onPressed: () => onSalary(salary),
      ),
    _add('Adicionar quem recebe salário', () => onSalary(null)),
    _row(
      title: 'Vale alimentação',
      subtitle: 'Não é dinheiro: só compra comida',
      amount: plan.voucher,
      onPressed: onVoucher,
    ),
    _add('Registrar dinheiro extra deste mês', onExtra),
  ];

  List<Widget> _group(String title, LineGroup group) => [
    CajuiSectionTitle(title),
    for (final line in plan.lines.where((line) => line.group == group))
      _row(
        title: line.name,
        subtitle: [
          categories[line.categoryId]?.name ?? 'Outra',
          ?line.note,
        ].join(' · '),
        amount: line.amount,
        onPressed: () => onLine(group, line),
      ),
    _add('Adicionar em ${title.toLowerCase()}', () => onLine(group, null)),
  ];

  /// As parcelas não se digitam: vêm das dívidas, e só aparecem aqui.
  List<Widget> _installments() => [
    const CajuiSectionTitle('Parcelas de dívida'),
    if (debts.isEmpty)
      const CajuiListRow(
        title: 'Nenhuma dívida cadastrada',
        subtitle: 'A parcela vem da dívida, em Dívidas',
      ),
    for (final debt in debts)
      CajuiListRow(
        title: debt.creditor,
        subtitle: 'Por mês · vem de Dívidas',
        trailing: CajuiAmountText(debt.installmentAmount.cents),
      ),
  ];

  Widget _row({
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
    Money? amount,
  }) => CajuiListRow(
    title: title,
    subtitle: subtitle,
    trailing: amount == null ? null : CajuiAmountText(amount.cents),
    semanticLabel:
        '$title, $subtitle${amount == null ? '' : ', ${_brl(amount)}'}',
    onPressed: readOnly ? null : onPressed,
  );

  Widget _add(String label, VoidCallback onPressed) => readOnly
      ? const SizedBox.shrink()
      : CajuiListRow(
          title: label,
          leading: const CajuiIcon(CajuiIconData.plus),
          semanticLabel: label,
          onPressed: onPressed,
        );
}
