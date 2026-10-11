import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_scope.dart';

/// A origem "notificação" atravessa o contrato como as outras: o servidor
/// lê a origem pelo nome, e o que o aparelho grava é o que sobe.
void main() {
  test('RN-786 · o lançamento da notificação sobe e volta com a origem '
      'intacta', () {
    final groceries = DefaultCatalog.emptyBook.categoryOf('groceries');
    final entry = Entry.create(
      id: 'notice-abc',
      description: 'Mercado Bom Preco',
      amount: const Money.fromCents(4590),
      occurredOn: testToday,
      category: groceries,
      paymentLines: [
        DefaultCatalog.paymentMethods.first.line(const Money.fromCents(4590)),
      ],
      today: testToday,
      origin: EntryOrigin.notification,
    ).valueOrNull!;

    final request = EntryCodec.fromEntry(entry);
    final back = EntryCodec.toEntry(
      CreateEntryRequest.fromJson(request.toJson()),
      category: groceries,
      today: testToday,
    ).valueOrNull!;

    expect(request.origin, 'notification');
    expect(back.origin, EntryOrigin.notification);
  });
}
