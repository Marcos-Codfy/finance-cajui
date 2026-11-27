import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

/// [description] no Pix, em [day] de setembro.
Entry _spend(String id, String description, int day, {int cents = 1000}) =>
    entry(
      id: id,
      description: description,
      cents: cents,
      lines: [pix(cents)],
      on: LocalDate(2026, 9, day),
    );

void main() {
  group('FrequentSpend.rank', () {
    test('o mais repetido vem primeiro, com o valor e a grafia da última '
        'vez', () {
      final ranked = FrequentSpend.rank([
        _spend('a', 'Padaria Central', 2, cents: 900),
        _spend('b', 'Ônibus', 3, cents: 500),
        _spend('c', 'PADARIA CENTRAL LTDA.', 10, cents: 1250),
        _spend('d', 'padaria central', 20, cents: 1100),
        _spend('e', 'Ônibus', 21, cents: 500),
      ], today: today);

      expect(
        [for (final s in ranked) s.description],
        ['padaria central', 'Ônibus'],
      );
      expect(ranked.first.count, 3);
      expect(ranked.first.amount, const Money.fromCents(1100));
      expect(ranked.first.paymentMethodId, 'pix');
    });

    test('no empate de contagem, o mais recente na frente', () {
      final ranked = FrequentSpend.rank([
        _spend('a', 'Feira', 1),
        _spend('b', 'Feira', 2),
        _spend('c', 'Farmácia', 25),
        _spend('d', 'Farmácia', 26),
      ], today: today);

      expect(ranked.first.description, 'Farmácia');
    });

    test('sem nada repetido, sugere repetir o último lançamento', () {
      final ranked = FrequentSpend.rank([
        _spend('a', 'Cinema', 5),
        _spend('b', 'Livraria', 18),
      ], today: today);

      expect(ranked.single.description, 'Livraria');
      expect(ranked.single.count, 1);
    });

    test('o que passou de 60 dias não é hábito, e livro vazio não sugere '
        'nada', () {
      final old = [
        entry(
          id: 'a',
          description: 'Academia',
          cents: 9000,
          lines: [pix(9000)],
          on: LocalDate(2026, 7, 1),
        ),
        entry(
          id: 'b',
          description: 'Academia',
          cents: 9000,
          lines: [pix(9000)],
          on: LocalDate(2026, 7, 2),
        ),
      ];

      expect(FrequentSpend.rank(old, today: today), isEmpty);
      expect(FrequentSpend.rank(const [], today: today), isEmpty);
    });

    test('no máximo [limit] sugestões', () {
      const places = ['Padaria', 'Feira', 'Posto', 'Farmácia', 'Ônibus'];
      final many = [
        for (final (i, place) in places.indexed) ...[
          _spend('a$i', place, 1 + i),
          _spend('b$i', place, 10 + i),
        ],
      ];

      expect(FrequentSpend.rank(many, today: today, limit: 3), hasLength(3));
    });
  });
}
