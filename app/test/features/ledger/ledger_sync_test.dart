import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_sync.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

final _today = LocalDate(2026, 9, 22);

/// Um servidor de mentira que guarda o que recebeu, como o de verdade faria.
final class _FakeUplink implements LedgerUplink {
  final Map<String, String> entries = {};
  final Set<String> categories = {};
  final List<String> calls = [];

  @override
  bool get isPaired => true;

  @override
  Future<(Set<String>, ErrorCode?)> remoteCategories() async =>
      (categories, null);

  @override
  Future<(Map<String, String>, ErrorCode?)> remoteEntries() async =>
      (Map.of(entries), null);

  @override
  Future<ErrorCode?> sendCategory(Map<String, Object?> category) async {
    categories.add('${category['id']}');
    return null;
  }

  @override
  Future<ErrorCode?> sendEntry(CreateEntryRequest entry) async {
    calls.add('criou ${entry.id}');
    entries[entry.id] = _signature(entry);
    return null;
  }

  @override
  Future<ErrorCode?> reviseEntry(CreateEntryRequest entry) async {
    calls.add('corrigiu ${entry.id}');
    entries[entry.id] = _signature(entry);
    return null;
  }

  @override
  Future<ErrorCode?> cancelEntry(String id) async {
    calls.add('cancelou $id');
    entries.remove(id);
    return null;
  }

  String _signature(CreateEntryRequest entry) => LedgerUplink.signature(
    cents: entry.amountCents,
    occurredOn: entry.occurredOn,
    categoryId: entry.categoryId,
    description: entry.description,
  );
}

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

LedgerBook _bookOf(List<Entry> entries) {
  final base = DefaultCatalog.emptyBook;
  return LedgerBook(
    categories: base.categories,
    paymentMethods: base.paymentMethods,
    entries: entries,
  );
}

void main() {
  late _FakeUplink uplink;
  late LedgerSync sync;

  setUp(() {
    uplink = _FakeUplink();
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

    test('aparelho sem cadastro não tenta subir nada', () async {
      final book = _bookOf([_entry('e1', 'Padaria', 850)]);

      final (sent, error) = await LedgerSync(_UnpairedUplink()).run(book);

      expect(sent, 0);
      expect(error, ErrorCode.auth03);
    });
  });
}

final class _UnpairedUplink extends _FakeUplink {
  @override
  bool get isPaired => false;
}
