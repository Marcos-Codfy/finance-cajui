import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/home/application/home_view.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Meu mês", como a aba da planilha do dono: o que entra, o que sai — em
/// cada grupo, o que conta de cada categoria — e se o mês fecha.
///
/// Nada aqui é conta da tela: os números vêm prontos de `MonthBudget`.
class MonthPage extends ConsumerWidget {
  /// Cria a tela.
  const new({super.key});

  /// Abre a tela.
  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push<void>(CajuiPageRoute(builder: (_) => const MonthPage()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(homeViewProvider);
    final finances = ref.watch(financesProvider);
    final back = Navigator.of(context).pop;
    if (view == null || finances == null) {
      return CajuiScreen(
        title: 'Meu mês',
        onBack: back,
        children: const [CajuiSkeleton(height: 240)],
      );
    }
    final budget = view.budget;
    return CajuiScreen(
      title: 'Meu mês',
      overline: DateLabels.month(budget.month),
      onBack: back,
      children: [
        ..._comesIn(budget, finances.plan),
        ..._goesOut(budget, finances.categories),
        ..._closes(budget),
      ],
    );
  }

  static Widget _row(String title, Money amount, {String? subtitle}) =>
      CajuiListRow(
        title: title,
        subtitle: subtitle,
        trailing: CajuiAmountText(amount.cents),
      );

  static List<Widget> _comesIn(MonthBudget budget, BudgetPlan plan) => [
    const CajuiSectionTitle('O que entra'),
    _row(
      'Dinheiro',
      budget.cashIncome,
      subtitle: plan.salaries.isEmpty
          ? 'Entradas do mês'
          : '${plan.salaries.map((salary) => salary.name).join(', ')} '
                'e extras · é este que paga as contas',
    ),
    _row(
      'Vale alimentação',
      budget.voucher,
      subtitle: 'Não é dinheiro: só compra comida',
    ),
  ];

  static List<Widget> _goesOut(
    MonthBudget budget,
    Map<String, Category> categories,
  ) => [
    const CajuiSectionTitle('O que sai'),
    ..._group('Contas fixas', Block.fixed, budget, categories),
    ..._group('Assinaturas', Block.subscription, budget, categories),
    ..._group('Gastos do dia a dia', Block.variable, budget, categories),
    _row(
      'Parcelas de dívida',
      budget.debtInstallments,
      subtitle: 'Vêm das dívidas cadastradas',
    ),
    if (budget.tithe.isPositive) _row('Dízimo', budget.tithe),
    _row('Total que sai', budget.totalOut),
  ];

  /// O total do grupo e, embaixo, cada categoria: o previsto, o gasto e o
  /// que conta — o maior dos dois (RN-1005).
  static List<Widget> _group(
    String title,
    Block block,
    MonthBudget budget,
    Map<String, Category> categories,
  ) {
    String brl(Money amount) => BrlFormatter.format(amount.cents);
    return [
      _row(title, budget.totalOf(block)),
      for (final item in budget.itemsOf(block))
        Padding(
          // Recuada, e sem caixa à esquerda: a categoria é parte do grupo de
          // cima, e não um item com ícone próprio.
          padding: const EdgeInsets.only(left: CajuiSpacing.lg),
          child: CajuiListRow(
            title: categories[item.categoryId]?.name ?? 'Outra',
            subtitle:
                'previsto ${brl(item.planned)} · gasto ${brl(item.spent)}',
            trailing: CajuiAmountText(item.counted.cents),
          ),
        ),
    ];
  }

  static List<Widget> _closes(MonthBudget budget) {
    final percent = budget.spentPercent;
    return [
      const CajuiSectionTitle('Sobrou ou faltou'),
      _row('O vale paga parte do mercado', budget.voucherCovered),
      _row('Precisa sair do bolso', budget.outOfPocket),
      _result(budget),
      _row(
        'Pode gastar por semana',
        budget.weeklyLimit,
        subtitle:
            'Depois de separar contas fixas, assinaturas, dívida e '
            'dízimo · ${BrlFormatter.format(budget.weeklyVoucher.cents)} '
            'é vale',
      ),
      CajuiListRow(
        title: 'Já está gasto',
        subtitle: 'Da sua renda em dinheiro',
        trailing: Text(percent == null ? '—' : '$percent%'),
      ),
    ];
  }

  /// Sobrou ou faltou, com a frase da planilha.
  static Widget _result(MonthBudget budget) => CajuiListRow(
    title: budget.closes ? 'Sobra' : 'Falta para o mês fechar',
    subtitle: budget.closes
        ? 'É quanto resta depois de pagar tudo'
        : 'É a meta de corte do mês',
    trailing: CajuiAmountText(
      (budget.closes ? budget.result : budget.shortfall).cents,
      tone: budget.closes
          ? CajuiAmountTone.positive
          : CajuiAmountTone.shortfall,
    ),
  );
}
