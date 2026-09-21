import 'package:cajui/src/features/debts/presentation/debt_detail_page.dart';
import 'package:cajui/src/features/debts/presentation/debt_form_page.dart';
import 'package:cajui/src/features/debts/presentation/debt_row.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// As dívidas cadastradas, uma a uma.
///
/// Esta tela nunca é a entrada do app, e o total das dívidas nunca é o número
/// em destaque dela (RN-540): ele aparece como soma no pé da lista. Cada
/// dívida fala primeiro do que falta — "faltam 7 parcelas de R$ 212,00" —,
/// com o já pago ao lado (RN-541).
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
    final debts = ref.watch(ledgerProvider).value?.debts ?? const <Debt>[];
    final open = [...debts.where((debt) => !debt.isPaidOff)];
    final paidOff = [...debts.where((debt) => debt.isPaidOff)];
    return CajuiScreen(
      title: 'Dívidas',
      onBack: Navigator.of(context).pop,
      footer: CajuiButton(
        label: 'Cadastrar dívida',
        icon: CajuiIconData.plus,
        expand: true,
        onPressed: () => DebtFormPage.open(context),
      ),
      children: [
        if (debts.isEmpty) _noDebtsYet,
        for (final debt in open) _row(context, debt),
        if (open.isNotEmpty) _OutstandingTotal(open),
        if (paidOff.isNotEmpty) ...[
          const CajuiSectionTitle('Quitadas'),
          for (final debt in paidOff) _row(context, debt),
        ],
      ],
    );
  }

  static const _noDebtsYet = CajuiEmptyState(
    title: 'Nenhuma dívida cadastrada',
    message:
        'Cadastrando cada dívida, o Cajui soma sozinho as parcelas do mês e '
        'diz quando cada uma termina.',
  );

  Widget _row(BuildContext context, Debt debt) => DebtRow(
    debt: debt,
    onPressed: () => DebtDetailPage.open(context, debt.id),
  );
}

/// O saldo devedor nominal somado: a soma das parcelas que faltam (RN-510).
/// Fica no pé da lista, e não em destaque.
class _OutstandingTotal extends StatelessWidget {
  const new(this.debts);

  final List<Debt> debts;

  Money get _total =>
      debts.fold(Money.zero, (sum, debt) => sum + debt.outstandingBalance);

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: CajuiSpacing.md),
      child: Text(
        'Somando o que falta de todas: ${BrlFormatter.format(_total.cents)}',
        style: theme.typography.label.copyWith(color: theme.colors.text.muted),
      ),
    );
  }
}
