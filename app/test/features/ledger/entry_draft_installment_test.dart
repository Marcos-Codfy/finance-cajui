import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

final CreditCard _card = CreditCard.create(
  id: 'card-1',
  name: 'Cartão',
  closingDay: 25,
  dueDay: 5,
).valueOrNull!;

/// Compra de R$ 100,00 em 3×, com o valor de parcela que a pessoa digitou.
EntryDraft _draft({int? each}) => EntryDraft(
  amountCents: 10000,
  description: 'Loja',
  category: DefaultCatalog.emptyBook.categoryOf('groceries'),
  method: const PaymentMethod(
    id: 'card-1',
    name: 'Cartão',
    kind: PaymentMethodKind.creditCard,
  ),
  occurredOn: LocalDate(2026, 9, 20),
  installments: 3,
  installmentAmountCents: each,
);

void main() {
  group('RN-314 · o valor da parcela digitado', () {
    test('33,33 em 3× de 100,00 é arredondamento, não juros negativos: a '
        'compra é dividida sem perder centavo', () {
      final draft = _draft(each: 3333);
      final plan = draft.installmentPlanFor(_card)!;

      expect(draft.interestCents, 0);
      expect(plan.interestTotal, Money.zero);
      expect(plan.total, const Money.fromCents(10000));
      expect(plan.installments.first.amount, const Money.fromCents(3334));
    });

    test('parcela que soma mais que a compra é juros, e fica guardada', () {
      final draft = _draft(each: 3600);
      final plan = draft.installmentPlanFor(_card)!;

      expect(draft.interestCents, 800);
      expect(plan.interestTotal, const Money.fromCents(800));
    });

    test('sem valor digitado, o total é dividido', () {
      final plan = _draft().installmentPlanFor(_card)!;

      expect(plan.interestTotal, Money.zero);
      expect(plan.total, const Money.fromCents(10000));
    });
  });
}
