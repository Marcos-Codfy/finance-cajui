import 'package:domain/src/budget/budget_line.dart';
import 'package:domain/src/budget/line_group.dart';
import 'package:domain/src/budget/month_setup.dart';
import 'package:domain/src/income/income_source.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/money/tender.dart';
import 'package:domain/src/shared/edit_stamp.dart';
import 'package:meta/meta.dart';

/// O plano da casa, como na planilha do dono (11/10/2026): o que entra, o
/// que sai todo mês e o dízimo.
///
/// Não é obrigatório. Sem plano, o mês conta só o que aconteceu; com ele, o
/// mês conta, em cada categoria, o maior entre o previsto e o gasto.
@immutable
final class BudgetPlan {
  /// Cria o plano.
  const new({
    this.salaries = const [],
    this.voucher = Money.zero,
    this.titheBasisPoints = 0,
    this.lines = const [],
    this.legacyDebtInstallments = Money.zero,
    this.definedAt,
  });

  /// O plano antigo lido como o novo: a renda vira o primeiro salário, cada
  /// fixo vira conta fixa e cada variável vira dia a dia pelo máximo — que é
  /// o "use o maior" da planilha. [nameOf] dá o nome da categoria.
  factory fromLegacy(
    MonthSetup setup, {
    required String Function(String categoryId) nameOf,
  }) => BudgetPlan(
    salaries: [
      if (setup.cashIncome.isPositive)
        IncomeSource(
          id: firstSalaryId,
          name: 'Renda',
          tender: Tender.cash,
          expectedAmount: setup.cashIncome,
          expectedDay: 5,
        ),
    ],
    lines: _legacyLines(setup, nameOf),
    legacyDebtInstallments: setup.debtInstallments,
    definedAt: setup.definedAt,
  );

  static List<BudgetLine> _legacyLines(
    MonthSetup setup,
    String Function(String categoryId) nameOf,
  ) => [
    for (final fixed in setup.fixedExpenses)
      ?BudgetLine.create(
        id: fixed.id,
        name: fixed.name,
        amount: fixed.amount,
        group: LineGroup.fixedBill,
        categoryId: fixed.categoryId,
        paymentMethodId: fixed.paymentMethodId,
        dueDay: fixed.dueDay,
      ).valueOrNull,
    for (final variable in setup.variableBudgets)
      ?BudgetLine.create(
        id: 'legacy-${variable.categoryId}',
        name: nameOf(variable.categoryId),
        amount: variable.range.max,
        group: LineGroup.dayToDay,
        categoryId: variable.categoryId,
        paymentMethodId: variable.voucherEligible ? 'voucher' : null,
      ).valueOrNull,
  ];

  /// O plano vazio: o mês conta só o que aconteceu.
  static const empty = BudgetPlan();

  /// O identificador da primeira renda. É o mesmo do plano antigo, para que
  /// o salário já registrado como recebido continue substituindo o esperado
  /// (RN-131).
  static const firstSalaryId = 'cash-income';

  /// Os salários, um por pessoa da casa, em dinheiro.
  final List<IncomeSource> salaries;

  /// O vale alimentação que entra por mês. Moeda separada (RN-111).
  final Money voucher;

  /// O dízimo, em centésimos de por cento da renda em dinheiro: 1000 é 10%.
  /// Zero quando não se paga.
  final int titheBasisPoints;

  /// "Minhas contas": o que sai todo mês.
  final List<BudgetLine> lines;

  /// As parcelas que o plano antigo guardava como um valor solto, sem
  /// dívida cadastrada. Continuam contando até a pessoa salvar um plano novo
  /// — que nunca tem esse valor: parcela vem da dívida, e não se digita.
  final Money legacyDebtInstallments;

  /// Quando foi definido. Entre dois aparelhos, vale o mais novo.
  final DateTime? definedAt;

  /// Se não há nada planejado.
  bool get isEmpty =>
      salaries.isEmpty &&
      lines.isEmpty &&
      voucher.isZero &&
      titheBasisPoints == 0 &&
      legacyDebtInstallments.isZero;

  /// O dízimo de [cashIncome], arredondado como todo valor (RN-103).
  Money titheOf(Money cashIncome) =>
      Money.ratio(cashIncome.orZeroIfNegative, titheBasisPoints, 10000);

  /// O mesmo plano com as partes dadas trocadas.
  BudgetPlan copyWith({
    List<IncomeSource>? salaries,
    Money? voucher,
    int? titheBasisPoints,
    List<BudgetLine>? lines,
  }) => BudgetPlan(
    salaries: salaries ?? this.salaries,
    voucher: voucher ?? this.voucher,
    titheBasisPoints: titheBasisPoints ?? this.titheBasisPoints,
    lines: lines ?? this.lines,
    legacyDebtInstallments: legacyDebtInstallments,
    definedAt: definedAt,
  );

  /// O plano salvo pela pessoa em [at]. Plano salvo agora nunca leva as
  /// parcelas soltas do plano antigo: parcela vem da dívida (RN-1003).
  BudgetPlan savedAt(DateTime at) => BudgetPlan(
    salaries: salaries,
    voucher: voucher,
    titheBasisPoints: titheBasisPoints,
    lines: lines,
    definedAt: at.toUtc(),
  );

  /// Se este plano é mais novo que [other].
  bool isNewerThan(BudgetPlan other) =>
      EditStamp.isNewer(definedAt, other.definedAt);
}
