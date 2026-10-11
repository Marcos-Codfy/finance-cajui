import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:server/src/ledger/ledger_state.dart';

/// O livro do servidor entregue ao domínio, que faz as contas da planilha
/// (ADR-023) — as mesmas que o aparelho mostra no Início.
///
/// O plano novo, as dívidas e a ordem de quitação chegam como fatos do
/// aparelho (ADR-019): o servidor os guarda como vieram, e só aqui os lê,
/// para a Juju falar com os números que a pessoa vê.
abstract final class ServerFinances {
  /// Os números da casa a partir de [state].
  ///
  /// O plano antigo entra como um plano a mais, como no aparelho: o mais
  /// novo vale.
  static Finances of(LedgerState state) {
    final facts = state.facts;
    return Finances(
      categories: state.categories,
      plans: [
        if (!state.plan.isEmpty)
          BudgetPlan.fromLegacy(
            state.plan,
            nameOf: (id) => state.categories[id]?.name ?? 'Conta',
          ),
        for (final fact in facts)
          if (fact.type == DeviceFact.budgetDefined)
            BudgetPlanCodec.decode(fact.payload),
      ],
      entries: state.entries,
      reversals: [...state.reversals.values],
      receipts: [...state.receipts.values],
      debts: _debts(facts),
      debtOrder: _order(facts),
      // O pagamento de parcela ligado à dívida já conta pela dívida.
      excluded: {
        for (final fact in facts)
          if (fact.type == DeviceFact.debtInstallmentPaid)
            DebtCodec.decodePayment(fact.payload).entryId,
      },
    );
  }

  /// A versão mais recente de cada dívida, na ordem em que chegaram.
  static List<Debt> _debts(List<DeviceFact> facts) {
    final byId = <String, Debt>{};
    for (final fact in facts) {
      if (fact.type != DeviceFact.debtDefined) continue;
      final debt = DebtCodec.decodeDebt(fact.payload);
      byId[debt.id] = debt;
    }
    return [...byId.values];
  }

  /// Vale a ordem mais nova inteira (RN-1031).
  static List<String> _order(List<DeviceFact> facts) {
    var ids = const <String>[];
    for (final fact in facts) {
      if (fact.type == DeviceFact.debtOrdered) {
        ids = DebtCodec.decodeOrdering(fact.payload).ids;
      }
    }
    return ids;
  }
}
