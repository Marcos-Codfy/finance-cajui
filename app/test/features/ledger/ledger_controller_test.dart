import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_ledger_journal.dart';
import '../../support/test_scope.dart';

final LedgerBook _book = DefaultCatalog.emptyBook;
final Category _groceries = _book.categoryOf('groceries');
final Category _utilities = _book.categoryOf('utilities');
final PaymentMethod _pix = _book.methodOf('pix');
final PaymentMethod _voucher = _book.methodOf('voucher');

EntryDraft _draft({
  int cents = 8600,
  Category? category,
  PaymentMethod? method,
  LocalDate? on,
}) => EntryDraft(
  amountCents: cents,
  description: 'Mercado Boa Compra',
  category: category ?? _groceries,
  method: method ?? _pix,
  occurredOn: on ?? testToday,
);

EntryDraft _split(int first, int second) => _draft(method: _voucher).copyWith(
  isSplit: true,
  secondMethod: _pix,
  firstCents: first,
  secondCents: second,
);

void main() {
  late MemoryLedgerJournal journal;
  late ProviderContainer container;

  LedgerController controller() => container.read(ledgerProvider.notifier);
  Future<int> recorded() async => (await journal.readAll()).length;

  setUp(() {
    journal = MemoryLedgerJournal();
    container = ProviderContainer(overrides: testOverrides(journal: journal));
    addTearDown(container.dispose);
  });

  group('lançar à mão (UC-ENTRY-01)', () {
    test('RN-201 · o lançamento aceito é gravado e aparece no mês', () async {
      final result = await controller().record(_draft());
      final book = await container.read(ledgerProvider.future);

      expect(result.isOk, isTrue);
      expect(await recorded(), 1);
      expect(book.entriesIn(testToday.budgetMonth).single.id, 'id-0');
      expect(book.spentIn(testToday.budgetMonth).cash.cents, 8600);
    });

    test('RN-206 · data de amanhã é recusada e nada é gravado', () async {
      final result = await controller().record(
        _draft(on: testToday.addDays(1)),
      );

      expect(result.failureOrNull, isA<PurchaseDateInFuture>());
      expect(await recorded(), 0);
    });

    test('RN-104 · valor zero é recusado', () async {
      final result = await controller().record(_draft(cents: 0));

      expect(result.failureOrNull, isA<NonPositiveAmount>());
    });
  });

  group('dividir entre vale e dinheiro (UC-ENTRY-02)', () {
    setUp(() async {
      await controller().setVoucherBalance(
        const Money.fromCents(3000),
        reason: 'teste',
      );
    });

    test('RN-122 e RN-111 · 30 no vale e 56 no Pix: o saldo zera e cada '
        'moeda conta no seu lado', () async {
      final result = await controller().record(_split(3000, 5600));
      final book = await container.read(ledgerProvider.future);
      final spent = book.spentIn(testToday.budgetMonth);

      expect(result.isOk, isTrue);
      expect(book.voucher.balance, Money.zero);
      expect(spent.mealVoucher.cents, 3000);
      expect(spent.cash.cents, 5600);
    });

    test('RN-122 · linha no vale maior que o saldo é recusada', () async {
      final result = await controller().record(_draft(method: _voucher));

      expect(result.failureOrNull, isA<VoucherBalanceExceeded>());
      expect(await recorded(), 1, reason: 'só o ajuste de saldo do preparo');
    });

    test('RN-112 · o vale não paga categoria fora de alimentação', () async {
      final result = await controller().record(
        _draft(cents: 2000, category: _utilities, method: _voucher),
      );

      expect(result.failureOrNull, isA<CategoryNotVoucherEligible>());
    });

    test(
      'RN-203 · linhas de 30 e 50 para uma compra de 86 não fecham',
      () async {
        final result = await controller().record(_split(3000, 5000));
        final failure = result.failureOrNull! as PaymentLinesMismatch;

        expect((failure.amount - failure.linesTotal).cents, 600);
      },
    );
  });

  group('saldo do vale (RN-123)', () {
    test('informar o saldo real grava um ajuste, não um lançamento', () async {
      await controller().setVoucherBalance(
        const Money.fromCents(16210),
        reason: 'saldo da operadora',
      );
      final book = await container.read(ledgerProvider.future);
      final event = (await journal.readAll()).single;

      expect(book.voucher.balance.cents, 16210);
      expect(book.entries, isEmpty);
      expect((event as VoucherBalanceAdjusted).adjustment.amount.cents, 16210);
    });

    test('saldo que já bate não gera fato nenhum', () async {
      await controller().setVoucherBalance(Money.zero, reason: 'igual');

      expect(await recorded(), 0);
    });
  });

  test('reabrir o app reconstrói o mesmo livro a partir dos fatos', () async {
    await controller().setVoucherBalance(
      const Money.fromCents(3000),
      reason: 'teste',
    );
    await controller().record(_split(3000, 5600));

    final reopened = ProviderContainer(
      overrides: testOverrides(journal: journal),
    );
    addTearDown(reopened.dispose);
    final book = await reopened.read(ledgerProvider.future);

    expect(book.entries, hasLength(1));
    expect(book.voucher.balance, Money.zero);
  });

  group('RN-781 · o lançamento sobe sozinho depois de gravado', () {
    test('com sessão aberta, gravar já manda para o servidor', () async {
      final uplink = _OpenUplink();
      final scope = ProviderContainer(
        overrides: testOverrides(journal: journal, uplink: uplink),
      );
      addTearDown(scope.dispose);
      final notifier = scope.read(ledgerProvider.notifier);

      await notifier.record(_draft());
      await notifier.quietSync.settled;

      expect(uplink.sent, ['id-0']);
    });

    test('sem sessão aberta, o lançamento é gravado aqui e espera: a '
        'digital não é pedida no meio do lançamento', () async {
      await controller().record(_draft());
      await controller().quietSync.settled;

      expect(await recorded(), 1, reason: 'gravado aqui, sempre');
    });
  });
}

/// Uma subida com sessão aberta, que guarda o que recebeu.
final class _OpenUplink implements LedgerUplink {
  final List<String> sent = [];

  @override
  bool get isPaired => true;

  @override
  bool get hasOpenSession => true;

  @override
  Future<(Set<String>, ErrorCode?)> remoteCategories() async =>
      ({for (final category in _book.categories) category.id}, null);

  @override
  Future<(Set<String>, ErrorCode?)> remoteCards() async =>
      (const <String>{}, null);

  @override
  Future<ErrorCode?> sendCard(Map<String, Object?> card) async => null;

  @override
  Future<(RemoteIncome, ErrorCode?)> remoteIncome() async =>
      ((receipts: const <String>{}, adjustments: const <String>{}), null);

  @override
  Future<ErrorCode?> sendIncome(Map<String, Object?> receipt) async => null;

  @override
  Future<ErrorCode?> sendVoucherAdjustment(
    Map<String, Object?> adjustment,
  ) async => null;

  @override
  Future<ErrorCode?> sendPlan(Map<String, Object?> plan) async => null;

  @override
  Future<(Map<String, String>, ErrorCode?)> remoteEntries() async =>
      (const <String, String>{}, null);

  @override
  Future<ErrorCode?> sendCategory(Map<String, Object?> category) async => null;

  @override
  Future<ErrorCode?> sendEntry(CreateEntryRequest entry) async {
    sent.add(entry.id);
    return null;
  }

  @override
  Future<ErrorCode?> reviseEntry(CreateEntryRequest entry) async => null;

  @override
  Future<(Set<String>, ErrorCode?)> remoteReversals() async =>
      (const <String>{}, null);

  @override
  Future<ErrorCode?> sendReversal(Map<String, Object?> reversal) async => null;

  @override
  Future<ErrorCode?> cancelEntry(String id) async => null;
}
