import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:server/src/ledger/ledger_state.dart';

/// O livro do servidor entregue ao domínio, que faz as contas da planilha
/// (ADR-023) — as mesmas que o aparelho mostra no Início.
///
/// O plano novo, as dívidas e a ordem de quitação chegam como fatos do
/// aparelho (ADR-019): o servidor os guarda como vieram, e só aqui os lê,
/// para a Juju falar com os números que a pessoa vê. As regras de leitura
/// são as do aparelho: a versão mais nova pelo carimbo vence, e a parcela
/// paga do modelo antigo conta na dívida.
abstract final class ServerFinances {
  /// Os números da casa a partir de [state].
  ///
  /// O plano antigo entra como um plano a mais, como no aparelho: o mais
  /// novo vale.
  static Finances of(LedgerState state) {
    final facts = state.facts;
    final versions = _versions(state, facts);
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
      debts: DebtVersions.of(versions).current,
      debtVersions: versions,
      debtOrder: _order(facts),
      // O pagamento de parcela ligado à dívida já conta pela dívida.
      excluded: {
        for (final fact in facts)
          if (fact.type == DeviceFact.debtInstallmentPaid)
            DebtCodec.decodePayment(fact.payload).entryId,
      },
    );
  }

  /// As versões das dívidas, na ordem de chegada, com a mais nova de cada
  /// somando as parcelas pagas que o modelo antigo registrava.
  static List<Debt> _versions(LedgerState state, List<DeviceFact> facts) {
    final versions = [
      for (final fact in facts)
        if (fact.type == DeviceFact.debtDefined)
          DebtCodec.decodeDebt(fact.payload),
    ];
    final newest = {
      for (final debt in DebtVersions.of(versions).current) debt.id: debt,
    };
    final payments = _payments(state, facts);
    return [
      for (final version in versions)
        if (identical(version, newest[version.id]))
          _paid(version, payments[version.id] ?? 0)
        else
          version,
    ];
  }

  /// Quantas parcelas o modelo antigo registrou como pagas, por dívida —
  /// só as de lançamento vivo, e cada lançamento uma vez, como no aparelho.
  static Map<String, int> _payments(LedgerState state, List<DeviceFact> facts) {
    final counted = <String>{};
    final byDebt = <String, int>{};
    for (final fact in facts) {
      if (fact.type != DeviceFact.debtInstallmentPaid) continue;
      final (:debtId, :entryId) = DebtCodec.decodePayment(fact.payload);
      if (state.entryOf(entryId) == null || !counted.add(entryId)) continue;
      byDebt[debtId] = (byDebt[debtId] ?? 0) + 1;
    }
    return byDebt;
  }

  /// [debt] com [paid] parcelas a mais, sem passar do total.
  static Debt _paid(Debt debt, int paid) {
    if (paid == 0 || debt.informedBalance != null) return debt;
    final total = debt.paidInstallments + paid;
    return debt.withPaidInstallments(
      total > debt.totalInstallments ? debt.totalInstallments : total,
    );
  }

  /// Vale a ordem mais nova pelo carimbo, inteira (RN-1031), e não a que
  /// chegou por último.
  static List<String> _order(List<DeviceFact> facts) {
    DebtOrdering? newest;
    for (final fact in facts) {
      if (fact.type != DeviceFact.debtOrdered) continue;
      final ordering = DebtCodec.decodeOrdering(fact.payload);
      if (newest == null || !newest.definedAt.isAfter(ordering.definedAt)) {
        newest = ordering;
      }
    }
    return newest?.ids ?? const [];
  }
}
