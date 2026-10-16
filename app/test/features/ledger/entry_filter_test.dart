import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/entry_filter.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

final _today = LocalDate(2026, 9, 20);
const _september = BudgetMonth(2026, 9);

PaymentLine _line(String method, PaymentMethodKind kind, int cents) =>
    PaymentLine(
      paymentMethodId: method,
      kind: kind,
      amount: Money.fromCents(cents),
    );

/// Um lançamento inventado: [cents] em [method], na categoria [category].
Entry _entry(
  String id,
  String description, {
  required LocalDate on,
  String category = 'other',
  String method = 'pix',
  int cents = 1000,
}) => Entry.create(
  id: id,
  description: description,
  amount: Money.fromCents(cents),
  occurredOn: on,
  category: DefaultCatalog.categories.firstWhere((c) => c.id == category),
  paymentLines: [
    _line(
      method,
      method == 'debit' ? PaymentMethodKind.debit : PaymentMethodKind.pix,
      cents,
    ),
  ],
  today: _today,
).valueOrNull!;

/// Metade no vale, metade no Pix (RN-204).
Entry _split(String id) => Entry.create(
  id: id,
  description: 'Mercado Boa Compra',
  amount: const Money.fromCents(4000),
  occurredOn: LocalDate(2026, 9, 12),
  category: DefaultCatalog.categories.firstWhere((c) => c.id == 'groceries'),
  paymentLines: [
    _line('voucher', PaymentMethodKind.mealVoucher, 2000),
    _line('pix', PaymentMethodKind.pix, 2000),
  ],
  today: _today,
).valueOrNull!;

List<String> _ids(List<Entry> entries) => [
  for (final entry in entries) entry.id,
];

void main() {
  final bakery = _entry(
    'bakery',
    'Padaria Pão Quente',
    on: LocalDate(2026, 9, 18),
    category: 'bakery',
    method: 'debit',
  );
  final pharmacy = _entry(
    'pharmacy',
    'FARMACIA SAO JOAO',
    on: LocalDate(2026, 9, 10),
    category: 'health',
  );
  final lastDayOfAugust = _entry(
    'august',
    'Açougue do Zé',
    on: LocalDate(2026, 8, 31),
    category: 'butcher',
  );
  final firstOfSeptember = _entry(
    'september-1',
    'Feira  da   Rua 99',
    on: LocalDate(2026, 9, 1),
    category: 'street-market',
  );
  final split = _split('split');
  final book = [pharmacy, lastDayOfAugust, bakery, firstOfSeptember, split];

  group('o mês', () {
    test('só o mês, do mais recente para o mais antigo: 31 de agosto fica '
        'de fora, 1º de setembro entra', () {
      const filter = EntryFilter(month: _september);

      expect(_ids(filter.apply(book)), [
        'bakery',
        'split',
        'pharmacy',
        'september-1',
      ]);
      expect(filter.isNarrowed, isFalse);
    });

    test('voltar um mês mostra só agosto', () {
      final filter = const EntryFilter(month: _september)
          .withMonth(_september.previous);

      expect(_ids(filter.apply(book)), ['august']);
    });

    test('mês sem lançamento devolve lista vazia, e não erro', () {
      const filter = EntryFilter(month: BudgetMonth(2026, 7));

      expect(filter.apply(book), isEmpty);
      expect(filter.apply(const []), isEmpty);
    });
  });

  group('a busca, sem caixa nem acento', () {
    EntryFilter search(String text) =>
        const EntryFilter(month: _september).withText(text);

    test('"farmácia são joão" acha o que o banco escreveu em maiúsculas e '
        'sem acento', () {
      expect(_ids(search('farmácia são joão').apply(book)), ['pharmacy']);
    });

    test('"PAO" acha "Pão Quente", e "pão" também', () {
      expect(_ids(search('PAO').apply(book)), ['bakery']);
      expect(_ids(search('pão').apply(book)), ['bakery']);
    });

    test('pedaço do meio da palavra também serve: "quent"', () {
      expect(_ids(search('quent').apply(book)), ['bakery']);
    });

    test('espaço repetido não atrapalha, e número é buscável: "rua 99"', () {
      expect(_ids(search('  rua   99 ').apply(book)), ['september-1']);
    });

    test('só espaço não é busca: a lista fica inteira e nada é recorte', () {
      final filter = search('   ');

      expect(filter.apply(book), hasLength(4));
      expect(filter.isNarrowed, isFalse);
    });

    test('texto que não está em descrição nenhuma esvazia a lista', () {
      final filter = search('posto de gasolina');

      expect(filter.apply(book), isEmpty);
      expect(filter.isNarrowed, isTrue);
    });

    test('a busca não atravessa o mês: "açougue" em setembro não acha o '
        'de agosto', () {
      expect(search('acougue').apply(book), isEmpty);
    });
  });

  group('categoria e forma de pagamento', () {
    test('a categoria deixa só a dela', () {
      const filter = EntryFilter(month: _september, categoryId: 'health');

      expect(_ids(filter.apply(book)), ['pharmacy']);
    });

    test('categoria sem lançamento no mês esvazia a lista', () {
      const filter = EntryFilter(month: _september, categoryId: 'rent');

      expect(filter.apply(book), isEmpty);
    });

    test('RN-204 · pagamento dividido aparece no vale e no Pix', () {
      const september = EntryFilter(month: _september);

      expect(_ids(september.withPaymentMethod('voucher').apply(book)), [
        'split',
      ]);
      expect(_ids(september.withPaymentMethod('pix').apply(book)), [
        'split',
        'pharmacy',
        'september-1',
      ]);
    });

    test('os recortes valem juntos: Pix **e** saúde', () {
      const filter = EntryFilter(
        month: _september,
        categoryId: 'health',
        paymentMethodId: 'pix',
      );

      expect(_ids(filter.apply(book)), ['pharmacy']);
      expect(
        filter.withPaymentMethod('debit').apply(book),
        isEmpty,
        reason: 'a farmácia foi no Pix, e não no débito',
      );
    });
  });

  group('tirar um recorte', () {
    const narrowed = EntryFilter(
      month: _september,
      text: 'pão',
      categoryId: 'bakery',
      paymentMethodId: 'debit',
    );

    test('null tira só aquele recorte, e o resto fica', () {
      final withoutCategory = narrowed.withCategory(null);

      expect(withoutCategory.categoryId, isNull);
      expect(withoutCategory.text, 'pão');
      expect(withoutCategory.paymentMethodId, 'debit');
      expect(narrowed.withPaymentMethod(null).categoryId, 'bakery');
    });

    test('limpar tira busca, categoria e forma de pagamento, e não o mês', () {
      final cleared = narrowed.withMonth(_september.previous).cleared;

      expect(cleared, EntryFilter(month: _september.previous));
      expect(cleared.isNarrowed, isFalse);
    });
  });
}
