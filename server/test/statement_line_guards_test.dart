import 'package:domain/domain.dart';
import 'package:server/src/ai/ai_statement_lines.dart';
import 'package:test/test.dart';

/// As duas linhas que entraram erradas em novembro/2026 e bagunçaram o mês:
/// o cabeçalho de mês lido como gasto e o pagamento da fatura lido como
/// despesa — o mesmo dinheiro contado duas vezes (RN-756).
void main() {
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
