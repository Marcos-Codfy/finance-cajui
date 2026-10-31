import 'package:cajui/src/core/navigation/navigation_providers.dart';
import 'package:cajui/src/core/navigation/scene_navigator.dart';
import 'package:cajui/src/features/budget/presentation/amount_page.dart';
import 'package:cajui/src/features/budget/presentation/bill_line_page.dart';
import 'package:cajui/src/features/budget/presentation/income_page.dart';
import 'package:cajui/src/features/budget/presentation/month_history_page.dart';
import 'package:cajui/src/features/budget/presentation/month_page.dart';
import 'package:cajui/src/features/budget/presentation/my_bills_page.dart';
import 'package:cajui/src/features/budget/presentation/salary_page.dart';
import 'package:cajui/src/features/budget/presentation/tithe_page.dart';
import 'package:cajui/src/features/budget/presentation/voucher_page.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Para onde levam as telas do plano e do mês (ADR-031).
///
/// É a "factory de cena" do Meu mês e das Minhas contas: monta cada tela com
/// os dados que ela pede e a abre. As telas só dizem o que a pessoa tocou.
final class BudgetCoordinator {
  /// Cria o coordinator sobre o navegador de cenas.
  const new(this._navigator);

  final SceneNavigator _navigator;

  /// O Meu mês: o que entra, o que sai e o que sobra.
  Future<void> openMonth() => _navigator.push<void>(const MonthPage());

  /// O histórico de meses fechados.
  Future<void> openMonthHistory() =>
      _navigator.push<void>(const MonthHistoryPage());

  /// As Minhas contas: renda, contas fixas, assinaturas e gastos do dia a dia.
  Future<void> openMyBills() => _navigator.push<void>(const MyBillsPage());

  /// Uma conta do plano; com [line], para alterá-la.
  Future<void> openBillLine(LineGroup group, {BudgetLine? line}) =>
      _navigator.push<void>(BillLinePage(group: group, line: line));

  /// O salário; com [salary], para alterá-lo.
  Future<void> openSalary({IncomeSource? salary}) =>
      _navigator.push<void>(SalaryPage(salary: salary));

  /// Registrar o que entrou, em dinheiro ou no vale ([tender]).
  Future<void> openIncome({Tender tender = Tender.cash}) =>
      _navigator.push<void>(IncomePage(tender: tender));

  /// O dízimo.
  Future<void> openTithe() => _navigator.push<void>(const TithePage());

  /// O vale alimentação.
  Future<void> openVoucher() => _navigator.push<void>(const VoucherPage());

  /// Pede um valor em reais e devolve os centavos, ou `null` se a pessoa
  /// desistiu.
  Future<int?> askAmount({
    required String title,
    required String label,
    required String explanation,
    int initialCents = 0,
  }) => _navigator.push<int>(
    AmountPage(
      title: title,
      label: label,
      explanation: explanation,
      initialCents: initialCents,
    ),
  );

  /// Fecha a tela atual devolvendo [result].
  void close([Object? result]) => _navigator.pop(result);
}

/// O coordinator do plano e do mês.
final budgetCoordinatorProvider = Provider<BudgetCoordinator>(
  (ref) => BudgetCoordinator(ref.watch(sceneNavigatorProvider)),
);
