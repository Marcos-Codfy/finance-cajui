import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_sync.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_uplink.dart';

final _today = LocalDate(2026, 9, 22);

Entry _entry(String id, String what, int cents) => Entry.create(
  id: id,
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
}) {
  final base = DefaultCatalog.emptyBook;
  return LedgerBook(
    categories: base.categories,
    paymentMethods: base.paymentMethods,
    entries: entries,
    receipts: receipts,
    voucherAdjustments: adjustments,
    setup: setup ?? MonthSetup.empty,
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

      final (first, _) = await sync.run(book);
      final (second, _) = await sync.run(book);

      expect(first, 1);
      expect(second, 0, reason: 'a segunda subida não tem o que mandar');
      expect(uplink.calls, ['criou e1']);
    });

    test(
      'lançamento corrigido sobe como correção, e não em duplicata',
      () async {
        await sync.run(_bookOf([_entry('e1', 'Padaria', 850)]));

        final (sent, _) = await sync.run(
          _bookOf([_entry('e1', 'Padaria', 900)]),
        );

        expect(sent, 1);
        expect(uplink.calls, ['criou e1', 'corrigiu e1']);
        expect(uplink.entries, hasLength(1));
      },
    );

    test('lançamento cancelado aqui é cancelado lá (RN-995)', () async {
      await sync.run(
        _bookOf([_entry('e1', 'Padaria', 850), _entry('e2', 'Feira', 2000)]),
      );

      final (sent, _) = await sync.run(_bookOf([_entry('e1', 'Padaria', 850)]));

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

      final (sent, error) = await sync.run(
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

    test('aparelho sem cadastro não tenta subir nada', () async {
      final book = _bookOf([_entry('e1', 'Padaria', 850)]);

      final (sent, error) = await LedgerSync(_UnpairedUplink()).run(book);

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
