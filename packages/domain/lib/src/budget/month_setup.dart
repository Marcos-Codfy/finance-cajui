import 'package:domain/src/budget/fixed_expense.dart';
import 'package:domain/src/budget/month_plan.dart';
import 'package:domain/src/budget/variable_budget.dart';
import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/shared/edit_stamp.dart';
import 'package:meta/meta.dart';

/// O que a pessoa cadastrou para o app conseguir planejar o mês: a renda em
/// dinheiro, os fixos, as faixas dos variáveis e as parcelas de dívida.
///
/// É a planilha de onde o Cajui nasceu, em forma de dado: três blocos de
/// despesa contra a renda, com os variáveis contados **pelo pior caso**.
///
/// Mora no domínio, e não no app, porque o servidor também precisa dele: sem
/// o plano, o assistente responde sobre o que já foi gasto mas não sobre o
/// que ainda pode ser (BL-049).
@immutable
final class MonthSetup {
  /// Cria o cadastro.
  const new({
    this.cashIncome = Money.zero,
    this.debtInstallments = Money.zero,
    this.fixedExpenses = const [],
    this.variableBudgets = const [],
    this.definedAt,
  });

  /// O cadastro de quem acabou de instalar o app.
  static const empty = MonthSetup();

  /// A renda em dinheiro esperada por mês. O vale não entra aqui: é outra
  /// moeda, e nenhum total soma as duas (RN-111).
  final Money cashIncome;

  /// As parcelas que saem todo mês e **não têm dívida cadastrada**: um valor
  /// só, para quem não quer cadastrar uma a uma. As dívidas cadastradas
  /// entram por fora (RN-504), somadas pelo domínio.
  final Money debtInstallments;

  /// As contas fixas.
  final List<FixedExpense> fixedExpenses;

  /// As faixas dos gastos variáveis, uma por categoria.
  final List<VariableBudget> variableBudgets;

  /// Quando este cadastro passou a valer, em UTC; `null` num registro
  /// antigo, de antes de dois aparelhos poderem discordar.
  ///
  /// É o que decide entre dois celulares: o plano com o `definedAt` mais
  /// novo vence, e não o que chegou por último ao servidor — quem sincroniza
  /// depois não apaga o que o outro editou antes por acaso.
  final DateTime? definedAt;

  /// Se este cadastro é mais novo que [other]. Sem carimbo dos dois lados,
  /// ninguém é mais novo, e vale o que já está.
  bool isNewerThan(MonthSetup other) =>
      EditStamp.isNewer(definedAt, other.definedAt);

  /// O mesmo cadastro carimbado com o instante [at] em que passou a valer.
  MonthSetup stamped(DateTime at) => MonthSetup(
    cashIncome: cashIncome,
    debtInstallments: debtInstallments,
    fixedExpenses: fixedExpenses,
    variableBudgets: variableBudgets,
    definedAt: at.toUtc(),
  );

  /// Se ainda não há nada cadastrado.
  bool get isEmpty =>
      cashIncome.isZero &&
      debtInstallments.isZero &&
      fixedExpenses.isEmpty &&
      variableBudgets.isEmpty;

  /// A soma das contas fixas cadastradas.
  Money get fixedTotal =>
      fixedExpenses.fold(Money.zero, (total, fixed) => total + fixed.amount);

  /// O plano de [month], com [voucherAvailable] de vale para gastar nele.
  ///
  /// [installmentsDue] são as parcelas que vencem no mês — das dívidas
  /// cadastradas e das compras parceladas no cartão. Entram ao lado das
  /// parcelas sem cadastro, como compromisso, e não consomem o orçamento dos
  /// variáveis (RN-312).
  MonthPlan planFor(
    BudgetMonth month, {
    required Money voucherAvailable,
    Money installmentsDue = Money.zero,
    Money? receivedCashIncome,
  }) => MonthPlan.of(
    month: month,
    // Recebido vale no lugar do esperado, no mês em que foi recebido
    // (RN-131).
    cashIncome: receivedCashIncome ?? cashIncome,
    voucherAvailable: voucherAvailable,
    fixedExpenses: fixedExpenses,
    variableBudgets: variableBudgets,
    debtInstallments: debtInstallments + installmentsDue,
  );

  /// O mesmo cadastro com a renda e as parcelas trocadas.
  MonthSetup withMoney({Money? cashIncome, Money? debtInstallments}) =>
      MonthSetup(
        cashIncome: cashIncome ?? this.cashIncome,
        debtInstallments: debtInstallments ?? this.debtInstallments,
        fixedExpenses: fixedExpenses,
        variableBudgets: variableBudgets,
        definedAt: definedAt,
      );

  /// O mesmo cadastro com o fixo [expense] incluído, no lugar do que tivesse
  /// o mesmo identificador.
  MonthSetup withFixed(FixedExpense expense) => _with(
    fixedExpenses: [...withoutFixed(expense.id).fixedExpenses, expense],
  );

  /// O mesmo cadastro sem o fixo [id].
  MonthSetup withoutFixed(String id) =>
      _with(fixedExpenses: [...fixedExpenses.where((fixed) => fixed.id != id)]);

  /// O mesmo cadastro com a faixa [budget], no lugar da que a categoria
  /// tivesse: cada categoria tem uma faixa só.
  MonthSetup withBudget(VariableBudget budget) => _with(
    variableBudgets: [
      ...withoutBudget(budget.categoryId).variableBudgets,
      budget,
    ],
  );

  /// O mesmo cadastro sem a faixa da categoria [categoryId].
  MonthSetup withoutBudget(String categoryId) => _with(
    variableBudgets: [
      ...variableBudgets.where((b) => b.categoryId != categoryId),
    ],
  );

  MonthSetup _with({
    List<FixedExpense>? fixedExpenses,
    List<VariableBudget>? variableBudgets,
  }) => MonthSetup(
    cashIncome: cashIncome,
    debtInstallments: debtInstallments,
    fixedExpenses: fixedExpenses ?? this.fixedExpenses,
    variableBudgets: variableBudgets ?? this.variableBudgets,
    definedAt: definedAt,
  );
}
