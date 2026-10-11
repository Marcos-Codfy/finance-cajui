import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('RN-1091 · a fala que conta um gasto', () {
    test('verbo de gasto e valor: vira lançamento', () {
      for (final said in [
        'gastei 40 no mercado no Pix',
        'Paguei 120 de luz',
        'comprei pão, 8,50 no débito',
        'lança 35 de Uber',
      ]) {
        expect(SpokenExpense.looksLikeExpense(said), isTrue, reason: said);
      }
    });

    test('pergunta não é gasto, mesmo com verbo e número', () {
      for (final said in [
        'quanto gastei em outubro?',
        'Quanto gastei nos últimos 30 dias',
        'onde gastei mais de 100',
      ]) {
        expect(SpokenExpense.looksLikeExpense(said), isFalse, reason: said);
      }
    });

    test(r'o valor dito: "40" é R$ 40,00, "8,50" e "8.50" são R$ 8,50, '
        '"1.200" é mil e duzentos', () {
      int? cents(String said) => SpokenExpense.amountOf(said)?.cents;

      expect(cents('gastei 40 no mercado'), 4000);
      expect(cents('comprei pão, 8,50 no débito'), 850);
      expect(cents('paguei 8.50 de café'), 850);
      expect(cents('paguei 1.200 de aluguel'), 120000);
      expect(cents('paguei 1200 de aluguel'), 120000);
      expect(cents('paguei a luz'), isNull);
    });

    test('a frase vai à conferência com o valor no rótulo de total, que o '
        'leitor do comprovante entende (RN-753)', () {
      final total = MoneyFormat.brl(const Money.fromCents(4000));

      expect(
        SpokenExpense.asReceipt('gastei 40 no mercado no Pix'),
        'gastei 40 no mercado no Pix\nTotal $total',
      );
    });

    test('sem valor não há o que lançar: "paguei a luz" fica com a Juju', () {
      expect(SpokenExpense.looksLikeExpense('paguei a luz'), isFalse);
      expect(SpokenExpense.looksLikeExpense('oi, Juju'), isFalse);
    });
  });
}
