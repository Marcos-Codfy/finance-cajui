import 'package:cajui/src/features/budget/application/month_overview.dart';
import 'package:cajui/src/features/budget/presentation/amount_page.dart';
import 'package:cajui/src/features/budget/presentation/fixed_expense_page.dart';
import 'package:cajui/src/features/budget/presentation/income_page.dart';
import 'package:cajui/src/features/budget/presentation/plan_sections.dart';
import 'package:cajui/src/features/budget/presentation/variable_budget_page.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O plano do mês: renda, contas fixas, faixas dos variáveis e parcelas de
/// dívida — os três blocos da planilha de onde o Cajui nasceu.
///
/// Cada mudança vale na hora, e a sobra planejada no topo responde a ela: a
/// pessoa vê o efeito de cada conta enquanto cadastra.
class PlanPage extends ConsumerWidget {
  /// Cria a tela do plano.
  const new({super.key});

  /// Abre a tela.
  static Future<void> open(BuildContext context) {
    return Navigator.of(context)
        .push<void>(CajuiPageRoute(builder: (_) => const PlanPage()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(ledgerProvider).value;
    final overview = ref.watch(monthOverviewProvider);
    if (book == null || overview == null) return const SizedBox.shrink();
    final edit = _PlanEditor(context, ref, book);
    return CajuiScreen(
      title: 'Plano do mês',
      onBack: Navigator.of(context).pop,
      children: [
        _plannedResult(overview),
        ...PlanSections.money(book.setup, edit.income, edit.debts),
        const SizedBox(height: CajuiSpacing.md),
        CajuiButton(
          label: 'Registrar recebimento',
          variant: CajuiButtonVariant.secondary,
          icon: CajuiIconData.wallet,
          onPressed: () => IncomePage.open(context),
        ),
        ...PlanSections.fixed(book.setup, edit.fixedExpense),
        ...PlanSections.variable(book, edit.variableBudget),
      ],
    );
  }

  Widget _plannedResult(MonthOverview overview) {
    final result = overview.indicators.plannedResult;
    return CajuiStatCard(
      label: 'Sobra planejada',
      cents: overview.hasIncome ? result.cents : null,
      tone: result.isNegative
          ? CajuiAmountTone.shortfall
          : CajuiAmountTone.positive,
      caption: 'Renda menos fixos, dívidas e variáveis pelo máximo',
    );
  }
}

/// As ações de edição do plano: cada uma abre a tela certa, espera o
/// resultado e grava o plano novo.
class _PlanEditor {
  new(this.context, this.ref, this.book);

  final BuildContext context;
  final WidgetRef ref;
  final LedgerBook book;

  MonthSetup get _setup => book.setup;

  Future<void> _define(MonthSetup setup) =>
      ref.read(ledgerProvider.notifier).definePlan(setup);

  Future<void> income() async {
    final cents = await AmountPage.open(
      context,
      title: 'Renda do mês',
      label: 'Renda em dinheiro',
      explanation:
          'O que entra em dinheiro por mês: salário e outras rendas. O vale '
          'alimentação fica de fora: é outra moeda, e o Cajui nunca soma as '
          'duas.',
      initialCents: _setup.cashIncome.cents,
    );
    if (cents == null) return;
    await _define(_setup.withMoney(cashIncome: Money.fromCents(cents)));
  }

  Future<void> debts() async {
    final cents = await AmountPage.open(
      context,
      title: 'Dívidas',
      label: 'Parcelas de dívida no mês',
      explanation:
          'A soma das parcelas de empréstimo e financiamento que saem todo '
          'mês. Compra parcelada no cartão não entra aqui.',
      initialCents: _setup.debtInstallments.cents,
    );
    if (cents == null) return;
    await _define(_setup.withMoney(debtInstallments: Money.fromCents(cents)));
  }

  Future<void> fixedExpense([FixedExpense? existing]) async {
    final saved = await FixedExpensePage.open(
      context,
      book: book,
      id: existing?.id ?? 'fixed-${ref.read(newIdProvider)()}',
      existing: existing,
    );
    if (saved != null) await _define(_setup.withFixed(saved));
  }

  Future<void> variableBudget([VariableBudget? existing]) async {
    final taken = {for (final b in _setup.variableBudgets) b.categoryId};
    final saved = await VariableBudgetPage.open(
      context,
      existing: existing,
      categories: [
        ...book.categories.where(
          (category) =>
              category.block == Block.variable &&
              (category.id == existing?.categoryId ||
                  !taken.contains(category.id)),
        ),
      ],
    );
    if (saved != null) await _define(_setup.withBudget(saved));
  }
}
