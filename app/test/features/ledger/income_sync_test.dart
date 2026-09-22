import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_sync.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_uplink.dart';

final _today = LocalDate(2026, 9, 22);

IncomeReceipt _receipt({
  String id = 'r1',
  Tender tender = Tender.mealVoucher,
  int cents = 50000,
}) => IncomeReceipt(
  id: id,
  sourceId: 'salario',
  tender: tender,
  amount: Money.fromCents(cents),
  receivedOn: _today,
);

LedgerBook _book({
  List<IncomeReceipt> receipts = const [],
  List<VoucherAdjustment> adjustments = const [],
}) {
  final base = DefaultCatalog.emptyBook;
  return LedgerBook(
    categories: base.categories,
    paymentMethods: base.paymentMethods,
    receipts: receipts,
    voucherAdjustments: adjustments,
  );
}

void main() {
  late FakeUplink uplink;
  late LedgerSync sync;

  setUp(() {
    uplink = FakeUplink();
    sync = LedgerSync(uplink);
  });

  group('BL-060 · o que entrou também sobe', () {
    test('RN-132 · o recebimento sobe, e não como lançamento', () async {
      await sync.run(_book(receipts: [_receipt()]));

      expect(uplink.income, {'r1'});
      expect(uplink.entries, isEmpty, reason: 'recebimento não é lançamento');
    });

    test('RN-123 · o acerto de saldo do vale sobe como fato', () async {
      await sync.run(
        _book(
          adjustments: [
            VoucherAdjustment(
              id: 'a1',
              amount: const Money.fromCents(-790),
              on: _today,
              reason: 'o cartão mostrava outro saldo',
            ),
          ],
        ),
      );

      expect(uplink.adjustments, {'a1'});
    });

    test('o que o servidor já tem não sobe de novo', () async {
      final book = _book(receipts: [_receipt(tender: Tender.cash)]);

      await sync.run(book);
      uplink.calls.clear();
      await sync.run(book);

      expect(uplink.income, {'r1'});
      expect(uplink.calls, isEmpty);
    });

    test('RN-111 · dinheiro e vale sobem como recebimentos separados, e '
        'nenhum total os soma', () async {
      await sync.run(
        _book(
          receipts: [
            _receipt(),
            _receipt(id: 'r2', tender: Tender.cash, cents: 320000),
          ],
        ),
      );

      expect(uplink.income, {'r1', 'r2'});
    });

    test('quem não recebeu nada ainda não manda nada', () async {
      await sync.run(_book());

      expect(uplink.income, isEmpty);
      expect(uplink.adjustments, isEmpty);
    });
  });
}
