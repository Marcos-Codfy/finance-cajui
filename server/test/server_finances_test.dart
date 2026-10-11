import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:server/src/assistant/server_finances.dart';
import 'package:server/src/ledger/ledger_state.dart';
import 'package:test/test.dart';

import 'support/juju_house.dart';
import 'support/tool_chat_client.dart';

/// Uma versão da conta de luz, com [balance] de saldo, carimbada em [at].
Map<String, Object?> _bill(String factId, int balance, DateTime at) => {
  'id': factId,
  'type': DeviceFact.debtDefined,
  'payload': DebtCodec.encodeDebt(
    Debt.withBalance(
      id: 'luz',
      creditor: 'Conta de luz',
      kind: DebtKind.overdueBill,
      balance: Money.fromCents(balance),
      monthlyPayment: const Money.fromCents(10000),
      dueDay: 25,
      informedOn: LocalDate(2026, 9, 20),
      definedAt: at,
    ).valueOrNull!,
  ),
};

Map<String, Object?> _order(String id, List<String> ids, DateTime at) => {
  'id': id,
  'type': DeviceFact.debtOrdered,
  'payload': DebtCodec.encodeOrdering((ids: ids, definedAt: at)),
};

/// O servidor de teste com [facts] gravados, lido como o domínio o lê.
Future<Finances> _finances(List<Map<String, Object?>> facts) async {
  final (server, token) = await jujuServer(ToolChatClient(const []));
  for (final fact in facts) {
    await server.call('POST', '/v1/facts', body: fact, token: token);
  }
  return ServerFinances.of(LedgerState(server.store.events));
}

void main() {
  test('ADR-024 · vale a versão mais nova da dívida pelo carimbo, e não a que '
      'chegou por último ao servidor', () async {
    final finances = await _finances([
      _bill('fato-10h', 80000, DateTime.utc(2026, 9, 20, 13)),
      _bill('fato-9h', 100000, DateTime.utc(2026, 9, 20, 12)),
    ]);

    expect(finances.debts.single.informedBalance, const Money.fromCents(80000));
  });

  test('a parcela paga do modelo antigo, de lançamento vivo, conta na dívida '
      'como no aparelho; a de lançamento que não existe, não', () async {
    final finances = await _finances([
      houseDebtFact,
      {
        'id': 'parcela-viva',
        'type': DeviceFact.debtInstallmentPaid,
        'payload': const {'debtId': 'debt-1', 'entryId': 'e1'},
      },
      {
        'id': 'parcela-morta',
        'type': DeviceFact.debtInstallmentPaid,
        'payload': const {'debtId': 'debt-1', 'entryId': 'cancelado'},
      },
    ]);

    // 5 do cadastro + 1 do lançamento vivo.
    expect(finances.debts.single.paidInstallments, 6);
  });

  test('RN-1031 · vale a ordem de quitação mais nova pelo carimbo', () async {
    final finances = await _finances([
      _order('ordem-nova', ['b', 'a'], DateTime.utc(2026, 9, 20, 13)),
      _order('ordem-velha', ['a', 'b'], DateTime.utc(2026, 9, 20, 12)),
    ]);

    expect(finances.debtOrder, ['b', 'a']);
  });
}
