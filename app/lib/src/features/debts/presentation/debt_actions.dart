import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/budget/application/plan_service.dart';
import 'package:cajui/src/features/budget/presentation/amount_page.dart';
import 'package:cajui/src/features/debts/application/debts_service.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O que dá para fazer com uma dívida: passá-la para o começo da fila de
/// quitação — "uma de cada vez" — e atualizar o saldo depois de negociar.
///
/// Não há botão de pagar a parcela: ela vem da dívida e cai sozinha a cada
/// vencimento (RN-1003, RN-1030).
class DebtActions extends ConsumerWidget {
  /// Cria as ações de [debt], que ainda deve [owed].
  const new({required this.debt, required this.owed, super.key});

  /// A dívida.
  final Debt debt;

  /// Quanto ainda se deve hoje.
  final Money owed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(clockProvider).today();
    final open = ref.watch(financesProvider)?.openDebtsOn(today);
    final first = open == null || open.isEmpty || open.first.id == debt.id;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!first && owed.isPositive)
          CajuiButton(
            label: 'Quitar esta primeiro',
            expand: true,
            onPressed: () => _first(ref, open),
          ),
        CajuiButton(
          label: owed.isPositive ? 'Atualizar quanto devo' : 'Mudar o saldo',
          variant: first
              ? CajuiButtonVariant.primary
              : CajuiButtonVariant.ghost,
          expand: true,
          onPressed: () => _balance(context, ref),
        ),
      ],
    );
  }

  Future<void> _first(WidgetRef ref, List<Debt>? open) =>
      ref.read(planServiceProvider).orderDebts([
        debt.id,
        for (final other in open ?? const <Debt>[])
          if (other.id != debt.id) other.id,
      ]);

  Future<void> _balance(BuildContext context, WidgetRef ref) async {
    final cents = await AmountPage.open(
      context,
      title: debt.creditor,
      label: 'Quanto ainda devo',
      explanation:
          'Depois de negociar, ou para dizer que quitou: zero. O saldo volta '
          'a cair sozinho a cada vencimento.',
      initialCents: owed.cents,
    );
    if (cents == null) return;
    await ref
        .read(debtsServiceProvider)
        .updateBalance(debt, Money.fromCents(cents));
  }
}
