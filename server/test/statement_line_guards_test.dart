import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:server/src/ai/ai_statement_lines.dart';
import 'package:server/src/ai/statement_movements.dart';
import 'package:test/test.dart';

/// As duas linhas que entraram erradas em novembro/2026 e bagunçaram o mês:
/// o cabeçalho de mês lido como gasto e o pagamento da fatura lido como
/// despesa — o mesmo dinheiro contado duas vezes (RN-756).
void main() {
  group('leitura por página', () {
    pageGuards();
    _repeatedGuard();
  });

  group('cabeçalho de mês não é movimentação', () {
    for (final header in [
      'Novembro',
      'NOVEMBRO 2026',
      'março de 2026',
      ' Outubro ',
    ]) {
      test('"$header" fica de fora', () {
        expect(AiStatementLines.isMonthHeader(header), isTrue);
      });
    }

    for (final name in ['Mercado Novembro', 'Padaria Março', 'Maio Lanches']) {
      test('"$name" é nome de loja, e fica', () {
        expect(AiStatementLines.isMonthHeader(name), isFalse);
      });
    }

    test('valor que não é texto não quebra', () {
      expect(AiStatementLines.isMonthHeader(null), isFalse);
      expect(AiStatementLines.isMonthHeader(12), isFalse);
    });
  });

  group('RN-756 · pagamento de fatura nunca é gasto, diga a IA o que for', () {
    for (final written in [
      'Pagamento da fatura',
      'PAGAMENTO FATURA NUBANK',
      'Pgto da fatura',
      'Fatura paga',
      'Pagamento de fatura',
    ]) {
      test('"$written" é pagamento de fatura', () {
        final (kind, doubtful) = AiStatementLines.kindOf('expense', written);
        expect(kind, StatementLineKind.cardPayment);
        expect(doubtful, isFalse);
      });
    }

    test('compra comum continua despesa', () {
      final (kind, _) = AiStatementLines.kindOf('expense', 'Supermercado');
      expect(kind, StatementLineKind.expense);
    });
  });
}

/// A leitura por página, que é a do app hoje, com as mesmas defesas.
List<StatementMovement> _page(List<String> lines, List<Object?> raw) =>
    StatementMovements.of(raw, (
      lines: lines,
      hasImage: false,
      categoryIds: const {},
      period: const BudgetMonth(2026, 11),
      today: LocalDate(2026, 11, 17),
    ));

Map<String, Object?> _out(int line, String name, int cents) => {
  'line': line,
  'day': 5,
  'month': 11,
  'description': name,
  'amountCents': cents,
  'kind': 'expense',
};

void pageGuards() {
  test(r'na página, o cabeçalho "NOVEMBRO -R$ 90,00" fica de fora mesmo que '
      'a IA o chame de outra coisa', () {
    final movements = _page(
      [r'NOVEMBRO -R$ 90,00', r'[2] 05/11 Padaria -R$ 40,00'],
      [_out(1, 'Açougue', 9000), _out(2, 'Padaria', 4000)],
    );
    expect([for (final m in movements) m.amount.cents], [4000]);
  });

  test('a saída que é a soma das outras é o total da página, e sai', () {
    final movements = _page(
      [
        r'05/11 Padaria -R$ 40,00',
        r'05/11 Mercado -R$ 30,00',
        r'05/11 Farmácia -R$ 20,00',
        r'05/11 Gastos do dia -R$ 90,00',
      ],
      [
        _out(1, 'Padaria', 4000),
        _out(2, 'Mercado', 3000),
        _out(3, 'Farmácia', 2000),
        _out(4, 'Gastos do dia', 9000),
      ],
    );
    expect([for (final m in movements) m.amount.cents], [4000, 3000, 2000]);
  });
}

void _repeatedGuard() {
  test('duas compras iguais não viram total uma da outra', () {
    final movements = _page(
      [r'05/11 Uber -R$ 20,00', r'[2] 05/11 Uber -R$ 20,00'],
      [_out(1, 'Uber', 2000), _out(2, 'Uber', 2000)],
    );
    expect(movements, hasLength(2));
  });
}
