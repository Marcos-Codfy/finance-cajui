import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:domain/domain.dart';

import 'test_scope.dart';

/// O nome da casa dos testes. Inventado, como todos os outros.
const testHouseholdName = 'Marcos Vinícius Muniz Arruda';

/// Os nomes da casa [names] como o fato que o livro guarda (RN-1070).
HouseholdNamed householdOf(List<String> names) => HouseholdNamed(
  HouseholdNames(names: names, definedAt: DateTime.utc(2026, 9, 1, 12)),
);

/// Um lançamento já no livro: [cents] no Pix, em [on], com [description],
/// nascido de [origin], na categoria [categoryId] do catálogo de fábrica.
EntryRecorded recordedEntry({
  required String id,
  required int cents,
  required LocalDate on,
  required String description,
  EntryOrigin origin = EntryOrigin.notification,
  String categoryId = 'other',
}) => EntryRecorded(
  Entry.create(
    id: id,
    description: description,
    amount: Money.fromCents(cents),
    occurredOn: on,
    category: DefaultCatalog.categories.firstWhere((c) => c.id == categoryId),
    paymentLines: [
      PaymentLine(
        paymentMethodId: 'pix',
        kind: PaymentMethodKind.pix,
        amount: Money.fromCents(cents),
      ),
    ],
    today: testToday,
    origin: origin,
  ).valueOrNull!,
);

/// O dia antes de [testToday].
final LocalDate testYesterday = LocalDate(2026, 9, 19);
