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

    test('sem valor não há o que lançar: "paguei a luz" fica com a Juju', () {
      expect(SpokenExpense.looksLikeExpense('paguei a luz'), isFalse);
      expect(SpokenExpense.looksLikeExpense('oi, Juju'), isFalse);
    });
  });
}
