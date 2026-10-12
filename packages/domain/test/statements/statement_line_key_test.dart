import 'package:domain/domain.dart';
import 'package:test/test.dart';

({LocalDate on, Money amount, String merchantKey}) _line(
  int day,
  int cents,
  String key,
) => (
  on: LocalDate(2026, 10, day),
  amount: Money.fromCents(cents),
  merchantKey: key,
);

void main() {
  group('RN-1117 · a chave pelo conteúdo, nunca pela posição', () {
    test('duas compras iguais no mesmo dia são a 1 e a 2', () {
      final keys = StatementLineKey.of([
        _line(3, 800, 'padaria boa vista'),
        _line(3, 800, 'padaria boa vista'),
      ]);

      expect(keys[0], endsWith('-1'));
      expect(keys[1], endsWith('-2'));
      expect(keys[0], isNot(keys[1]));
    });

    test('ler noutra ordem dá as mesmas chaves', () {
      final a = _line(3, 800, 'padaria boa vista');
      final b = _line(4, 1500, 'ifood');

      expect(
        StatementLineKey.of([a, b]).toSet(),
        StatementLineKey.of([b, a]).toSet(),
      );
    });

    test('a chave leva o dia, o valor e o lugar resumido, sem o nome', () {
      final key = StatementLineKey.of([_line(3, 800, 'padaria boa vista')]);

      expect(key.single, 'st-2026-10-03-800-3a36b76c-1');
    });
  });

  group('RN-1119 · gravar, ler de novo, desfazer e lançar de novo', () {
    const base = 'st-2026-10-03-800-3a36b76c-1';

    test('nunca gravada: a chave com o carimbo da leitura', () {
      final id = StatementLineKey.idFor(
        base,
        launch: 'L1',
        activeIds: const [],
      );

      expect(id, (id: '$base~L1', alreadyThere: false));
    });

    test('gravada e ativa, por esta leitura ou por outra: já está lá', () {
      for (final active in [base, '$base~L0']) {
        final id = StatementLineKey.idFor(
          base,
          launch: 'L1',
          activeIds: [active],
        );

        expect(id.alreadyThere, isTrue, reason: active);
      }
    });

    test('desfeita: lançar de novo grava com o carimbo novo, que nunca foi '
        'desfeito em lugar nenhum', () {
      final id = StatementLineKey.idFor(
        base,
        launch: 'L2',
        activeIds: const [],
      );

      expect(id, (id: '$base~L2', alreadyThere: false));
    });

    test('a ordem 1 não confunde com a ordem 10', () {
      final id = StatementLineKey.idFor(
        base,
        launch: 'L1',
        activeIds: ['${base}0~L0'],
      );

      expect(id.alreadyThere, isFalse);
    });
  });
}
