import 'package:cajui/src/features/assistant/application/answer_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('o atalho debaixo da resposta da Juju', () {
    test('sobra, falta, entra e sai levam ao Meu mês', () {
      for (final text in [
        r'Sobram R$ 530,90 neste mês.',
        r'Faltam R$ 120,00 para fechar.',
        r'Entra R$ 3.000,00 e sai do bolso R$ 2.500,00.',
        r'Você gastou R$ 86,00 no mercado.',
      ]) {
        expect(AnswerLink.of(text), AnswerLink.month, reason: text);
      }
    });

    test('dívida leva às dívidas, mesmo falando de sobra junto', () {
      expect(
        AnswerLink.of(r'Ainda deve R$ 772,00; a sobra não muda.'),
        AnswerLink.debts,
      );
      expect(AnswerLink.of(r'Abati R$ 500,00 da dívida.'), AnswerLink.debts);
    });

    test('sem valor em reais, ou sem assunto do mês, não aponta', () {
      expect(AnswerLink.of('Certo, lancei.'), isNull);
      expect(AnswerLink.of('A sobra do mês está boa.'), isNull);
      expect(AnswerLink.of(r'Lancei R$ 35,00 no mercado.'), isNull);
    });
  });
}
