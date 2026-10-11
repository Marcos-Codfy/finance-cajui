import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart' as fixtures;

final _day10 = LocalDate(2026, 9, 10);
final _day11 = LocalDate(2026, 9, 11);

/// Um lançamento de [cents], em [on], com [description], nascido de
/// [origin]. Nomes inventados.
Entry _entry(
  String id,
  int cents,
  LocalDate on,
  String description, {
  EntryOrigin origin = EntryOrigin.notification,
}) => Entry.create(
  id: id,
  description: description,
  amount: Money.fromCents(cents),
  occurredOn: on,
  category: fixtures.leisure,
  paymentLines: [fixtures.pix(cents)],
  today: fixtures.today,
  origin: origin,
).valueOrNull!;

BankReading _pix(int cents, LocalDate on, String? who) => BankReading(
  app: BankApp.nubank,
  kind: MovementKind.pixSent,
  amount: Money.fromCents(cents),
  occurredOn: on,
  counterpart: who,
);

void main() {
  group('RN-1075 · nomes compatíveis', () {
    test('o mesmo lugar, um cortado no fim, e a mesma pessoa abreviada', () {
      expect(
        NoticeTwin.namesAgree(
          'Padaria Central do Bai',
          'PADARIA CENTRAL DO BAIRRO LTDA',
        ),
        isTrue,
      );
      expect(
        NoticeTwin.namesAgree('Joana P Lima', 'JOANA PEREIRA LIMA'),
        isTrue,
      );
      expect(
        NoticeTwin.namesAgree('Mercado Bom Preco', 'MERCADO BOM PRECO LTDA'),
        isTrue,
      );
    });

    test('uma palavra só não basta, e sobrenome diferente é outra pessoa', () {
      expect(NoticeTwin.namesAgree('Padaria', 'Padaria Sol'), isFalse);
      expect(NoticeTwin.namesAgree('Joana Lima', 'Joana Souza'), isFalse);
      expect(NoticeTwin.namesAgree('', 'Joana Souza'), isFalse);
    });
  });

  group('RN-1076 · o comprovante que a notificação já lançou', () {
    test(r'ontem, R$ 150,00, "Joana P Lima": o comprovante de hoje para '
        'JOANA PEREIRA LIMA é o mesmo Pix', () {
      final notice = _entry('notice-n1', 15000, _day10, 'Joana P Lima');

      final twin = NoticeTwin.ofReceipt(
        [notice],
        amount: const Money.fromCents(15000),
        occurredOn: _day11,
        name: 'JOANA PEREIRA LIMA',
      );

      expect(twin, same(notice));
    });

    test('a notificação sem nome ("Pix enviado") e o comprovante sem nome '
        'lido bastam pelo valor e pela data', () {
      final unnamed = _entry('notice-n1', 15000, _day10, 'Pix enviado');
      final named = _entry('notice-n2', 9000, _day10, 'Joana P Lima');

      expect(
        NoticeTwin.ofReceipt(
          [unnamed],
          amount: const Money.fromCents(15000),
          occurredOn: _day10,
          name: 'JOANA PEREIRA LIMA',
        ),
        same(unnamed),
      );
      expect(
        NoticeTwin.ofReceipt(
          [named],
          amount: const Money.fromCents(9000),
          occurredOn: _day11,
        ),
        same(named),
      );
    });

    test('não é: outro valor, dois dias, outro nome, ou lançamento que não '
        'veio de notificação', () {
      final entries = [
        _entry('a', 15000, _day10, 'Joana P Lima'),
        _entry('b', 15100, _day11, 'Joana P Lima'),
        _entry('c', 15000, _day11, 'Joana Souza'),
        _entry('d', 15000, _day11, 'Joana Lima', origin: EntryOrigin.share),
      ];

      final twin = NoticeTwin.ofReceipt(
        entries,
        amount: const Money.fromCents(15000),
        occurredOn: LocalDate(2026, 9, 12),
        name: 'JOANA PEREIRA LIMA',
      );

      expect(twin, isNull);
    });

    test('com o Pix de ontem e o de hoje no livro, o comprovante de hoje é o '
        'de hoje', () {
      final yesterday = _entry('n1', 5000, _day10, 'Lucas Lima');
      final todays = _entry('n2', 5000, _day11, 'Lucas Lima');

      final twin = NoticeTwin.ofReceipt(
        [yesterday, todays],
        amount: const Money.fromCents(5000),
        occurredOn: _day11,
        name: 'LUCAS LIMA',
      );

      expect(twin, same(todays));
    });
  });

  group('RN-1077 · a notificação que chega depois do comprovante', () {
    test('comprovante do dia 10 para Joana Pereira Lima; notificação do dia '
        '11 para JOANA P LIMA → já está no livro', () {
      final shared = _entry(
        'c1',
        15000,
        _day10,
        'Joana Pereira Lima',
        origin: EntryOrigin.share,
      );

      expect(
        NoticeTwin.ofNotice([shared], _pix(15000, _day11, 'JOANA P LIMA')),
        same(shared),
      );
    });

    test('no mesmo dia, o mesmo valor basta, venha de onde vier (RN-789)', () {
      final manual = _entry(
        'm1',
        4590,
        _day11,
        'Mercado',
        origin: EntryOrigin.manual,
      );

      expect(
        NoticeTwin.ofNotice([manual], _pix(4590, _day11, 'OUTRO NOME')),
        same(manual),
      );
    });

    test(r'Pix de R$ 50,00 para Lucas Lima avisado no dia 10 e no dia 11 são '
        'dois lançamentos', () {
      final first = _entry('notice-n1', 5000, _day10, 'Lucas Lima');

      expect(
        NoticeTwin.ofNotice([first], _pix(5000, _day11, 'LUCAS LIMA')),
        isNull,
      );
    });

    test('a um dia, sem nome ou com nome que não casa, lança', () {
      final shared = _entry(
        'c1',
        15000,
        _day10,
        'Joana Pereira Lima',
        origin: EntryOrigin.share,
      );

      expect(NoticeTwin.ofNotice([shared], _pix(15000, _day11, null)), isNull);
      expect(
        NoticeTwin.ofNotice([shared], _pix(15000, _day11, 'JOANA SOUZA')),
        isNull,
      );
    });
  });
}
