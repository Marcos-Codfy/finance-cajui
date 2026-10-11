import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_sync.dart';
import 'package:cajui/src/features/ledger/application/sync_trail.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_uplink.dart';

final _today = LocalDate(2026, 9, 22);

Entry _entry(String id, String what, int cents, {DateTime? revisedAt}) =>
    Entry.create(
      id: id,
      revisedAt: revisedAt,
      description: what,
      amount: Money.fromCents(cents),
      occurredOn: _today,
      category: DefaultCatalog.emptyBook.categoryOf('groceries'),
      paymentLines: [
        DefaultCatalog.emptyBook.methodOf('pix').line(Money.fromCents(cents)),
      ],
      today: _today,
    ).valueOrNull!;

LedgerBook _bookOf(
  List<Entry> entries, {
  MonthSetup? setup,
  List<IncomeReceipt> receipts = const [],
  List<VoucherAdjustment> adjustments = const [],
  Set<String> cancelled = const {},
  List<LedgerEvent> facts = const [],
}) {
  final base = DefaultCatalog.emptyBook;
  return LedgerBook(
    categories: base.categories,
    paymentMethods: base.paymentMethods,
    entries: entries,
    receipts: receipts,
    voucherAdjustments: adjustments,
    setup: setup ?? MonthSetup.empty,
    trail: SyncTrail(cancelledIds: cancelled, facts: facts),
  );
}

const MonthSetup _plan = MonthSetup(cashIncome: Money.fromCents(320000));

void main() {
  late FakeUplink uplink;
  late LedgerSync sync;

  setUp(() {
    uplink = FakeUplink();
    sync = LedgerSync(uplink);
  });

  group('RN-781 · o livro sobe para o servidor ter com que responder', () {
    test(
      'a categoria vai antes: sem ela o servidor recusaria (E-REQ-02)',
      () async {
        await sync.run(_bookOf([_entry('e1', 'Padaria', 850)]));

        expect(uplink.categories, contains('groceries'));
        expect(uplink.entries.keys, contains('e1'));
      },
    );

    test('BL-049 · o plano sobe junto, depois dos lançamentos', () async {
      await sync.run(_bookOf([_entry('e1', 'Padaria', 850)], setup: _plan));

      expect(uplink.plan?['cashIncomeCents'], 320000);
      expect(uplink.calls, ['criou e1', 'plan']);
    });

    test('quem ainda não planejou não manda plano vazio: apagaria o que o '
        'servidor já tem', () async {
      await sync.run(_bookOf([_entry('e1', 'Padaria', 850)]));

      expect(uplink.plan, isNull);
      expect(uplink.calls, isNot(contains('plan')));
    });

    test('o que falta sobe, e o que já está lá não sobe de novo', () async {
      final book = _bookOf([_entry('e1', 'Padaria', 850)]);

      final (sent: first, received: _, error: _, pulled: _) = await sync.run(
        book,
      );
      final (sent: second, received: _, error: _, pulled: _) = await sync.run(
        book,
      );

      expect(first, 1);
      expect(second, 0, reason: 'a segunda subida não tem o que mandar');
      expect(uplink.calls, ['criou e1']);
    });

    test(
      'lançamento corrigido sobe como correção, e não em duplicata',
      () async {
        await sync.run(_bookOf([_entry('e1', 'Padaria', 850)]));

        final (:sent, received: _, error: _, pulled: _) = await sync.run(
          _bookOf([_entry('e1', 'Padaria', 900)]),
        );

        expect(sent, 1);
        expect(uplink.calls, ['criou e1', 'corrigiu e1']);
        expect(uplink.entries, hasLength(1));
      },
    );

    test(
      'BL-062 · o que o servidor tem e este aparelho nunca teve NÃO é '
      'cancelado: ainda não desceu, e cancelar apagaria o do outro',
      () async {
        uplink.entries['do-outro'] = 'x';

        await sync.run(_bookOf(const []));

        expect(uplink.calls, isNot(contains('cancelou do-outro')));
        expect(uplink.entries.keys, contains('do-outro'));
      },
    );

    test('BL-062 · versão mais velha que a do servidor não sobe por cima: é a '
        'descida que a corrige', () async {
      await sync.run(_bookOf([_entry('e1', 'Padaria', 850)]));
      uplink.entries['e1'] = 'corrigido-no-outro';
      uplink.revisedOnServer['e1'] = DateTime.utc(2026, 9, 22, 12);

      final (:sent, received: _, error: _, pulled: _) = await sync.run(
        _bookOf([_entry('e1', 'Padaria', 850)]),
      );

      expect(sent, 0);
      expect(uplink.calls, ['criou e1'], reason: 'não corrigiu por cima');
    });

    test(
      'BL-062 · a correção mais nova daqui sobe por cima da do servidor',
      () async {
        await sync.run(_bookOf([_entry('e1', 'Padaria', 850)]));
        uplink.entries['e1'] = 'corrigido-no-outro';
        uplink.revisedOnServer['e1'] = DateTime.utc(2026, 9, 22, 12);

        final (:sent, received: _, error: _, pulled: _) = await sync.run(
          _bookOf([
            _entry(
              'e1',
              'Padaria',
              900,
              revisedAt: DateTime.utc(2026, 9, 22, 13),
            ),
          ]),
        );

        expect(sent, 1);
        expect(uplink.calls.last, 'corrigiu e1');
      },
    );

    test('ADR-019 · a parcela de dívida paga sobe depois do lançamento '
        'que a pagou, e não sobe de novo', () async {
      const paid = DebtInstallmentPaid(debtId: 'debt-1', entryId: 'e1');
      final book = _bookOf([_entry('e1', 'Parcela', 21200)], facts: [paid]);

      await sync.run(book);
      await sync.run(book);

      expect(uplink.calls, ['criou e1', 'guardou debt-payment-e1']);
    });

    test('lançamento cancelado aqui é cancelado lá (RN-995)', () async {
      await sync.run(
        _bookOf([_entry('e1', 'Padaria', 850), _entry('e2', 'Feira', 2000)]),
      );

      final (:sent, received: _, error: _, pulled: _) = await sync.run(
        _bookOf([_entry('e1', 'Padaria', 850)], cancelled: {'e2'}),
      );

      expect(sent, 1);
      expect(uplink.calls.last, 'cancelou e2');
      expect(uplink.entries.keys, ['e1']);
    });

    test('um lançamento recusado não cala os que vêm depois dele', () async {
      // A compra parcelada era recusada pelo servidor, e o laço parava ali:
      // tudo lançado depois dela nunca subia, e o assistente respondia com
      // um mês pela metade sem dizer que estava pela metade.
      final teimoso = _RefusingOne('e2');
      final sync = LedgerSync(teimoso);

      final (:sent, received: _, :error, pulled: _) = await sync.run(
        _bookOf([
          _entry('e1', 'Padaria', 850),
          _entry('e2', 'Fogão', 96000),
          _entry('e3', 'Feira', 2000),
        ]),
      );

      expect(error, ErrorCode.req01, reason: 'a recusa é relatada');
      expect(sent, 2, reason: 'os outros dois subiram assim mesmo');
      expect(teimoso.entries.keys, containsAll(['e1', 'e3']));
    });

    test('um fato recusado não cala os fatos nem os recebimentos que vêm '
        'depois dele', () async {
      // O plano com um nome longo demais era recusado, e a subida parava
      // ali: as dívidas e os salários seguintes nunca chegavam ao servidor.
      final teimoso = _RefusingFirstFact();
      final debt = Debt.withBalance(
        id: 'd1',
        creditor: 'Carnê',
        kind: DebtKind.loan,
        balance: const Money.fromCents(50000),
        monthlyPayment: const Money.fromCents(5000),
        dueDay: 10,
        informedOn: _today,
      ).valueOrNull!;
      final book = _bookOf(
        const [],
        receipts: [
          IncomeReceipt(
            id: 'r1',
            tender: Tender.cash,
            amount: const Money.fromCents(10000),
            receivedOn: _today,
          ),
        ],
        facts: [
          DebtOrdered(ids: const ['x'], definedAt: DateTime.utc(2026, 9)),
          DebtDefined(id: 'divida', debt: debt),
        ],
      );

      final (sent: _, received: _, :error, pulled: _) = await LedgerSync(
        teimoso,
      ).run(book);

      expect(error, ErrorCode.req01, reason: 'a recusa é relatada');
      expect(teimoso.facts, contains('divida'));
      expect(teimoso.income, contains('r1'));
    });

    test('aparelho sem cadastro não tenta subir nada', () async {
      final book = _bookOf([_entry('e1', 'Padaria', 850)]);

      final (:sent, received: _, :error, pulled: _) = await LedgerSync(
        _UnpairedUplink(),
      ).run(book);

      expect(sent, 0);
      expect(error, ErrorCode.auth03);
    });
  });
}

final class _UnpairedUplink extends FakeUplink {
  @override
  bool get isPaired => false;
}

/// Recusa um lançamento e aceita os outros, como o servidor fazia com a
/// compra parcelada.
final class _RefusingOne extends FakeUplink {
  new(this.refused);

  final String refused;

  @override
  Future<ErrorCode?> sendEntry(CreateEntryRequest entry) async =>
      entry.id == refused ? ErrorCode.req01 : await super.sendEntry(entry);
}

/// Recusa o primeiro fato e aceita os outros, como o servidor faz com o
/// texto acima do teto.
final class _RefusingFirstFact extends FakeUplink {
  var _refused = false;

  @override
  Future<ErrorCode?> sendFact(DeviceFact fact) async {
    if (_refused) return await super.sendFact(fact);
    _refused = true;
    return ErrorCode.req01;
  }
}
