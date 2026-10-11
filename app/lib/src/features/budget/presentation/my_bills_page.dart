import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/budget/application/plan_service.dart';
import 'package:cajui/src/features/budget/presentation/amount_page.dart';
import 'package:cajui/src/features/budget/presentation/bill_line_page.dart';
import 'package:cajui/src/features/budget/presentation/income_page.dart';
import 'package:cajui/src/features/budget/presentation/my_bills_rows.dart';
import 'package:cajui/src/features/budget/presentation/salary_page.dart';
import 'package:cajui/src/features/budget/presentation/tithe_page.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:cajui/src/features/ledger/application/today_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Minhas contas", como a aba da planilha: o que entra — um salário por
/// pessoa, o vale, o extra do mês —, o que sai todo mês em cada grupo, as
/// parcelas que vêm das dívidas e o dízimo.
///
/// Cada mudança é salva na hora: não há botão de salvar para esquecer.
class MyBillsPage extends ConsumerWidget {
  /// Cria a tela.
  const new({super.key});

  /// Abre a tela.
  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push<void>(CajuiPageRoute(builder: (_) => const MyBillsPage()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finances = ref.watch(financesProvider);
    final back = Navigator.of(context).pop;
    if (finances == null) {
      return CajuiScreen(
        title: 'Minhas contas',
        onBack: back,
        children: const [CajuiSkeleton(height: 240)],
      );
    }
    final readOnly = !ref.watch(ledgerUplinkProvider).isPaired;
    final rows = MyBillsRows(
      plan: finances.plan,
      categories: finances.categories,
      debts: finances.openDebtsOn(ref.watch(todayProvider)),
      readOnly: readOnly,
      onLine: (group, line) => BillLinePage.open(context, group, line: line),
      onSalary: (salary) => SalaryPage.open(context, salary: salary),
      onVoucher: () => _voucher(context, ref, finances.plan),
      onExtra: () => IncomePage.open(context),
      onTithe: () => TithePage.open(context),
    );
    return CajuiScreen(
      title: 'Minhas contas',
      overline: 'Só mexa no que mudou: o resto o app calcula',
      onBack: back,
      children: rows.all(),
    );
  }

  /// O vale que entra por mês: um valor só, na tela de valor de sempre.
  static Future<void> _voucher(
    BuildContext context,
    WidgetRef ref,
    BudgetPlan plan,
  ) async {
    final cents = await AmountPage.open(
      context,
      title: 'Vale alimentação',
      label: 'Quanto entra por mês',
      explanation:
          'O vale não é dinheiro: só compra comida. Ele paga o mercado até '
          'o que entra por mês.',
      initialCents: plan.voucher.cents,
    );
    if (cents == null) return;
    // Relido depois da espera: o outro aparelho pode ter salvo o plano
    // enquanto a tela de valor estava aberta.
    final current = ref.read(financesProvider)?.plan ?? plan;
    await ref
        .read(planServiceProvider)
        .define(current.copyWith(voucher: Money.fromCents(cents)));
  }
}
