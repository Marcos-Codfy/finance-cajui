import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('RN-960 · a pergunta que o Cajui responde sozinho não vira token', () {
    test(
      'escrita com pressa, sem acento e sem pontuação, ainda é entendida',
      () {
        // É assim que se digita no celular, andando.
        expect(
          QuestionRouter.of('quanto da pra gastar nesta semana'),
          QuestionIntent.weekLimit,
        );
        expect(
          QuestionRouter.of('Quanto dá para gastar nesta semana?'),
          QuestionIntent.weekLimit,
        );
      },
    );

    test('cada intenção reconhece as formas de perguntar dela', () {
      const cases = {
        'Como o mês está fechando?': QuestionIntent.monthClosing,
        'qual a sobra do mês': QuestionIntent.monthClosing,
        'Para onde foi o dinheiro deste mês?': QuestionIntent.whereMoneyWent,
        'onde gastei mais': QuestionIntent.whereMoneyWent,
        'quanto tenho no vale': QuestionIntent.voucherBalance,
        'quanto vai vir na fatura': QuestionIntent.cardBill,
        'quanto devo ainda': QuestionIntent.debts,
        'quanto gastei hoje': QuestionIntent.today,
      };

      cases.forEach((question, expected) {
        expect(QuestionRouter.of(question), expected, reason: question);
      });
    });

    test('"hoje" ganha de "semana": o gatilho mais restrito vem primeiro', () {
      expect(
        QuestionRouter.of('quanto gastei hoje nesta semana'),
        QuestionIntent.today,
      );
    });

    test('pergunta aberta continua indo para a IA, que é para isso', () {
      // Errar para `unknown` não custa nada; errar para o outro lado custaria
      // uma resposta fora do assunto.
      const open = [
        'vale a pena trocar meu plano de celular?',
        'me explica o que é renda comprometida',
        'se eu comprar um tênis de 300 reais, complica?',
        'bom dia',
      ];

      for (final question in open) {
        expect(
          QuestionRouter.of(question),
          QuestionIntent.unknown,
          reason: question,
        );
      }
    });

    test('o texto normalizado perde acento, caixa e espaço sobrando', () {
      expect(
        QuestionRouter.of('   NESTA   SEMANA  '),
        QuestionIntent.weekLimit,
      );
      expect(QuestionRouter.normalize('Ação  ÚNICA'), 'acao unica');
    });
  });
}
