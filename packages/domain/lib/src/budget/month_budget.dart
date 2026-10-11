import 'package:domain/src/budget/budget_item.dart';
import 'package:domain/src/budget/budget_plan.dart';
import 'package:domain/src/calendar/budget_month.dart';
import 'package:domain/src/indicators/percent.dart';
import 'package:domain/src/ledger/block.dart';
import 'package:domain/src/ledger/category.dart';
import 'package:domain/src/money/money.dart';
import 'package:meta/meta.dart';

/// O mês como na planilha do dono (11/10/2026): o que entra, o que sai, o
/// que o vale cobre, sobrou ou faltou, e quanto dá para gastar por semana.
///
/// É função pura: os mesmos números no celular, na web e no servidor, e a
/// IA nunca calcula nenhum deles (RN-601, RN-602).
@immutable
final class MonthBudget {
  const new _({
    required this.month,
    required this.cashIncome,
    required this.voucher,
    required this.debtInstallments,
    required this.tithe,
    required this.items,
    required this.foodSpending,
  });

  /// Monta o mês. [spent] é o gasto por categoria, nas duas moedas;
  /// [cashIncome] é a renda em dinheiro (salários e extras); [voucher] é o
  /// vale do mês; [debtInstallments] são as parcelas que vencem no mês, que
  /// vêm das dívidas e nunca de lançamento digitado.
  factory of({
    required BudgetMonth month,
    required BudgetPlan plan,
    required Map<String, Category> categories,
    required Map<String, Money> spent,
    required Money cashIncome,
    required Money voucher,
    required Money debtInstallments,
  }) {
    final items = _items(plan, categories, spent);
    return MonthBudget._(
      month: month,
      cashIncome: cashIncome,
      voucher: voucher.orZeroIfNegative,
      debtInstallments: debtInstallments + plan.legacyDebtInstallments,
      tithe: plan.titheOf(cashIncome),
      items: items,
      foodSpending: items
          .where(
            (item) => categories[item.categoryId]?.voucherEligible ?? false,
          )
          .fold(Money.zero, (sum, item) => sum + item.counted),
    );
  }

  static List<BudgetItem> _items(
    BudgetPlan plan,
    Map<String, Category> categories,
    Map<String, Money> spent,
  ) {
    final planned = <String, Money>{};
    final groupOf = <String, Block>{};
    for (final line in plan.lines) {
      planned[line.categoryId] =
          (planned[line.categoryId] ?? Money.zero) + line.amount;
      groupOf.putIfAbsent(line.categoryId, () => line.block);
    }
    return [
      for (final id in {...planned.keys, ...spent.keys})
        BudgetItem(
          categoryId: id,
          block: groupOf[id] ?? _groupOfSpending(categories[id]),
          planned: planned[id] ?? Money.zero,
          spent: spent[id] ?? Money.zero,
        ),
    ];
  }

  /// O gasto lançado numa categoria de dívida — juros, tarifa — é gasto do
  /// dia a dia: a parcela de dívida vem só da dívida cadastrada.
  static Block _groupOfSpending(Category? category) {
    final block = category?.block ?? Block.variable;
    return block == Block.debt ? Block.variable : block;
  }

  /// O mês.
  final BudgetMonth month;

  /// O que entra em dinheiro: salários e extras. É este que paga as contas.
  final Money cashIncome;

  /// O vale do mês. Não é dinheiro: só paga comida (RN-111).
  final Money voucher;

  /// As parcelas de dívida do mês.
  final Money debtInstallments;

  /// O dízimo, um percentual da renda em dinheiro.
  final Money tithe;

  /// Cada categoria, com o previsto, o gasto e o que conta.
  final List<BudgetItem> items;

  /// O gasto com comida, pelo que conta: é o que o vale pode cobrir.
  final Money foodSpending;

  /// As categorias de [block].
  Iterable<BudgetItem> itemsOf(Block block) =>
      items.where((item) => item.block == block);

  /// O total de [block], pelo que conta em cada categoria.
  Money totalOf(Block block) => block == Block.debt
      ? debtInstallments
      : itemsOf(block).fold(Money.zero, (sum, item) => sum + item.counted);

  /// Contas fixas.
  Money get fixedBills => totalOf(Block.fixed);

  /// Assinaturas.
  Money get subscriptions => totalOf(Block.subscription);

  /// Gastos do dia a dia.
  Money get dayToDay => totalOf(Block.variable);

  /// O total que sai: `fixas + assinaturas + dia a dia + parcelas + dízimo`.
  Money get totalOut =>
      fixedBills + subscriptions + dayToDay + debtInstallments + tithe;

  /// O que é certo sair antes do dia a dia.
  Money get _committed => fixedBills + subscriptions + debtInstallments + tithe;

  /// O que o vale paga do mercado: `min(vale, gasto com comida)`.
  Money get voucherCovered {
    final food = foodSpending.orZeroIfNegative;
    return food < voucher ? food : voucher;
  }

  /// O que precisa sair do bolso: `total que sai − o que o vale cobre`.
  Money get outOfPocket => totalOut - voucherCovered;

  /// Sobra (positivo) ou falta (negativo): `dinheiro − sai do bolso`.
  Money get result => cashIncome - outOfPocket;

  /// O mês fecha: a sobra é zero ou mais.
  bool get closes => !result.isNegative;

  /// Quanto falta para o mês fechar; zero quando fecha.
  Money get shortfall => (-result).orZeroIfNegative;

  /// Quanto dá para gastar por semana: o que sobra depois de separar contas
  /// fixas, assinaturas, parcelas e dízimo, mais o que o vale cobre,
  /// dividido por quatro. Nunca negativo; limite arredonda para baixo
  /// (RN-103).
  Money get weeklyLimit => Money.ratioFloor(
    (cashIncome - _committed + voucherCovered).orZeroIfNegative,
    1,
    4,
  );

  /// A parte do limite da semana que é vale: a tela mostra as duas moedas
  /// separadas, porque elas nunca se somam na mão da pessoa (RN-111).
  Money get weeklyVoucher {
    final part = Money.ratioFloor(voucherCovered, 1, 4);
    return part > weeklyLimit ? weeklyLimit : part;
  }

  /// O quanto da renda já está gasto: `sai do bolso ÷ dinheiro`, em
  /// percentual inteiro. Passa de 100 quando o mês não fecha. Nulo sem
  /// renda em dinheiro (RN-604).
  int? get spentPercent => Percent.of(outOfPocket, cashIncome);
}
