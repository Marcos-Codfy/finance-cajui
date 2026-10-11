import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/debts/presentation/debt_detail_page.dart';
import 'package:cajui/src/features/debts/presentation/debt_form_page.dart';
import 'package:cajui/src/features/debts/presentation/debt_row.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// As dívidas de verdade, como na planilha: só o que atravessa mais de um
/// mês, na ordem em que vão ser quitadas — "uma de cada vez".
///
/// O total nunca é o número em destaque (RN-540): fica no pé, somando as
/// dívidas e as parcelas de cartão que ainda vão vencer.
class DebtsPage extends ConsumerWidget {
  /// Cria a tela de dívidas.
  const new({super.key});

  /// Abre a tela.
  static Future<void> open(BuildContext context) {
    return Navigator.of(context)
        .push<void>(CajuiPageRoute(builder: (_) => const DebtsPage()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finances = ref.watch(financesProvider);
    final today = ref.watch(clockProvider).today();
    final debts = finances?.debts ?? const <Debt>[];
    final open = finances?.openDebtsOn(today) ?? const <Debt>[];
    final paidOff = [...debts.where((debt) => !open.contains(debt))];
    return CajuiScreen(
      title: 'Minhas dívidas',
      overline: 'Só o que você paga em mais de um mês',
      onBack: Navigator.of(context).pop,
      footer: CajuiButton(
        label: 'Cadastrar dívida',
        icon: CajuiIconData.plus,
        expand: true,
        onPressed: () => DebtFormPage.open(context),
      ),
      children: [
        if (debts.isEmpty) _noDebtsYet,
        for (final (index, debt) in open.indexed)
          _row(context, debt, today, position: index + 1),
        if (finances != null && finances.owedOn(today).isPositive)
          _Owed(finances.owedOn(today)),
        if (paidOff.isNotEmpty) ...[
          const CajuiSectionTitle('Quitadas'),
          for (final debt in paidOff) _row(context, debt, today),
        ],
      ],
    );
  }

  static const _noDebtsYet = CajuiEmptyState(
    title: 'Nenhuma dívida cadastrada',
    message:
        'Dívida é só o que você paga em mais de um mês: parcelamento, carnê, '
        'conta atrasada ou rotativo do cartão. Compra no cartão paga inteira '
        'na fatura seguinte é gasto do mês.',
  );

  Widget _row(
    BuildContext context,
    Debt debt,
    LocalDate today, {
    int? position,
  }) => DebtRow(
    debt: debt,
    owed: DebtCalendar.outstandingOn(debt, today),
    position: position,
    onPressed: () => DebtDetailPage.open(context, debt.id),
  );
}

/// Quanto ainda devo, somando as dívidas e as parcelas de cartão que ainda
/// vão vencer (RN-1032). Fica no pé da lista, e não em destaque.
class _Owed extends StatelessWidget {
  const new(this.total);

  final Money total;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: CajuiSpacing.md),
      child: Text(
        'Quanto ainda devo, com as parcelas de cartão: '
        '${BrlFormatter.format(total.cents)}',
        style: theme.typography.label.copyWith(color: theme.colors.text.muted),
      ),
    );
  }
}
