import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/household.dart';

Money _brl(num reais) => Money.fromCents((reais * 100).round());

PaymentLine _line(String id, PaymentMethodKind kind, int cents) => PaymentLine(
  paymentMethodId: id,
  kind: kind,
  amount: Money.fromCents(cents),
);

/// O mercado de R$ 86,00 do exemplo: R$ 30,00 no vale e R$ 56,00 no Pix.
final Entry _groceries = Entry.create(
  id: 'mercado',
  description: 'Mercado do bairro',
  amount: _brl(86),
  occurredOn: LocalDate(2026, 10, 3),
  category: householdCategories['groceries']!,
  paymentLines: [
    _line('vale', PaymentMethodKind.mealVoucher, 3000),
    _line('pix', PaymentMethodKind.pix, 5600),
  ],
  today: LocalDate(2026, 12, 31),
).valueOrNull!;

final Entry _bus = spend(
  5000,
  id: 'onibus',
  category: 'transport',
  on: LocalDate(2026, 10, 5),
);

Reversal _back(Entry entry, int cents, LocalDate on) => Reversal.create(
  id: 'estorno-${entry.id}',
  entry: entry,
  paymentMethodId: 'pix',
  amount: Money.fromCents(cents),
  occurredOn: on,
).valueOrNull!;

String _name(String id) => switch (id) {
  'pix' => 'Pix',
  'vale' => 'Vale alimentação',
  _ => id,
};

MonthExport _export({
  List<Entry> entries = const [],
  List<Reversal> reversals = const [],
}) {
  final finances = household(entries: entries);
  return MonthExport.of(
    month: october,
    budget: finances.budgetFor(october),
    entries: entries,
    reversals: reversals,
    categories: householdCategories,
    methodName: _name,
  );
}

void main() {
  group('RN-1090 · o mês vira planilha', () {
    test(r'o exemplo: três linhas, dinheiro R$ 96,00 e vale R$ 30,00, '
        'nunca somados', () {
      final export = _export(
        entries: [_bus, _groceries],
        reversals: [_back(_bus, 1000, LocalDate(2026, 10, 7))],
      );

      expect(
        [for (final row in export.rows) row.description],
        ['Mercado do bairro', 'Compra onibus', 'Estorno: Compra onibus'],
      );
      // 56 + 50 − 10 = 96 em dinheiro; os 30 do vale ficam à parte.
      expect(export.cashTotal, _brl(96));
      expect(export.voucherTotal, _brl(30));
    });

    test('a linha diz a categoria, o grupo da planilha e as formas de '
        'pagamento, juntas', () {
      final row = _export(entries: [_groceries]).rows.single;

      expect(row.category, 'Mercado');
      expect(row.group, 'Dia a dia');
      expect(row.method, 'Vale alimentação + Pix');
      expect((row.cash, row.voucher), (_brl(56), _brl(30)));
    });

    test('o estorno entra no mês em que voltou, negativo, mesmo de uma '
        'compra de outro mês', () {
      final september = spend(
        12000,
        id: 'farmacia',
        category: 'health',
        on: LocalDate(2026, 9, 28),
      );
      final export = _export(
        entries: [september],
        reversals: [_back(september, 4000, LocalDate(2026, 10, 2))],
      );

      final row = export.rows.single;
      expect(row.isReversal, isTrue);
      expect(row.description, 'Estorno: Compra farmacia');
      expect(row.cash, _brl(-40));
      expect(row.on, LocalDate(2026, 10, 2));
    });

    test('o resumo traz os números do Meu mês, com as palavras da planilha '
        '(RN-1060)', () {
      final summary = {
        for (final line in _export().summary) line.label: line.amount,
      };
      final month = household().budgetFor(october);

      expect(summary['O que entra, em dinheiro'], month.cashIncome);
      expect(summary['Total que sai'], month.totalOut);
      expect(summary['Sai do bolso'], month.outOfPocket);
      expect(summary['Sobra do mês'], month.result);
      expect(summary.keys, isNot(contains('Faltam para fechar o mês')));
      expect(
        VoiceGuide.violations(summary.keys.join(' ')),
        isEmpty,
        reason: 'nada de déficit nem de palavra de banco',
      );
    });
  });
}
