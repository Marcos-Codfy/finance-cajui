import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:domain/domain.dart';

import '../../support/test_scope.dart';

/// Um gasto fictício de [cents], em [categoryId], há [daysAgo] dias.
Entry reviewEntry(
  String id, {
  required String categoryId,
  int cents = 2500,
  int daysAgo = 0,
  String description = 'Gasto',
  EntryOrigin origin = EntryOrigin.manual,
}) {
  final on = testToday.addDays(-daysAgo);
  return Entry.create(
    id: id,
    description: description,
    amount: Money.fromCents(cents),
    occurredOn: on,
    category: DefaultCatalog.emptyBook.categoryOf(categoryId),
    paymentLines: [
      DefaultCatalog.paymentMethods.first.line(Money.fromCents(cents)),
    ],
    today: testToday,
    origin: origin,
  ).valueOrNull!;
}

/// A semana dos testes da revisão: o que entra nela e o que fica de fora.
///
/// - `auto`: lançado pela notificação do banco, em Mercado, ontem — entra;
/// - `outros`: digitado sem categoria, há três dias — entra;
/// - `velho`: em Outros, mas há dez dias — fica de fora;
/// - `certo`: digitado em Restaurante, hoje — fica de fora.
final List<LedgerEvent> reviewWeek = [
  EntryRecorded(
    reviewEntry(
      'auto',
      categoryId: 'groceries',
      daysAgo: 1,
      description: 'Mercado Bom Preco',
      origin: EntryOrigin.notification,
    ),
  ),
  EntryRecorded(
    reviewEntry(
      'outros',
      categoryId: 'other',
      daysAgo: 3,
      description: 'Pão de queijo',
    ),
  ),
  EntryRecorded(reviewEntry('velho', categoryId: 'other', daysAgo: 10)),
  EntryRecorded(reviewEntry('certo', categoryId: 'eating-out')),
];
