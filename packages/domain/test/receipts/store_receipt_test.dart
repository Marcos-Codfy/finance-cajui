import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/store_receipt.dart';

final LocalDate _today = LocalDate(2026, 9, 21);

void main() {
  group('cupom fiscal de supermercado', () {
    test('RN-753 · o valor é o que saiu do bolso, e não o total antes do '
        'desconto', () {
      final candidates = ReceiptFieldReader.amountCandidates(storeReceiptText);

      expect(candidates, hasLength(1));
      expect(candidates.single.cents, 65358);
    });

    test('o estabelecimento é a loja do cabeçalho, nunca o endereço', () {
      final merchant = MerchantReader.nameIn(storeReceiptText);

      expect(merchant, 'MAR DOCE SUPERMERCADOS LTDA');
    });

    test('o endereço sozinho não passa por nome', () {
      const onlyAddress = '''
AV JOAQUIM EXEMPLO,5500,PLANO DIRETOR SUL,PALMAS
QUADRA 104 SUL RUA SO 5
CEP 77020-000''';

      expect(MerchantReader.nameIn(onlyAddress), isNull);
    });

    test('o nome sai da própria linha do CNPJ quando vêm juntos', () {
      const together = r'''
Cupom fiscal
MAR DOCE SUPERMERCADOS LTDA CNPJ: 11.222.333/0001-81
AV JOAQUIM EXEMPLO,5500
Valor a Pagar R$ 10,00''';

      expect(MerchantReader.nameIn(together), 'MAR DOCE SUPERMERCADOS LTDA');
    });

    test('o ramo vem do nome: é compra de mercado antes de a IA opinar', () {
      final merchant = MerchantReader.nameIn(storeReceiptText);

      expect(MerchantReader.kindIn(merchant), MerchantKind.supermarket);
    });

    test('RN-746 · a data ausente no cupom deixa o campo vazio', () {
      expect(
        ReceiptFieldReader.dateIn(storeReceiptText, today: _today),
        isNull,
      );
    });

    test('o documento é uma compra', () {
      expect(
        ReceiptFieldReader.documentKindIn(storeReceiptText),
        DocumentKind.purchase,
      );
    });
  });

  group('ramo do estabelecimento', () {
    void kindOf(String? name, MerchantKind? expected) =>
        expect(MerchantReader.kindIn(name), expected, reason: name);

    test('lê o ramo dos nomes mais comuns', () {
      kindOf('PADARIA PAO QUENTE', MerchantKind.bakery);
      kindOf('DROGARIA SAO BENTO', MerchantKind.pharmacy);
      kindOf('AUTO POSTO CERRADO', MerchantKind.fuel);
      kindOf('LANCHONETE E RESTAURANTE SABOR DA PRACA', MerchantKind.dining);
      kindOf('HORTIFRUTI DO VALE', MerchantKind.produce);
      kindOf('ATACADAO DIA A DIA', MerchantKind.supermarket);
      kindOf('ACOUGUE BOI BRAVO', MerchantKind.butcher);
      kindOf('LOJA DE FERRAGENS', null);
      kindOf(null, null);
    });

    test('açougue ganha de mercado quando o nome tem os dois', () {
      kindOf('MERCADO DE CARNES DO ZE', MerchantKind.butcher);
    });
  });

  group('nome na tela', () {
    test('a forma jurídica sai e o grito vira nome', () {
      expect(
        MerchantName.pretty('MAR DOCE SUPERMERCADOS LTDA'),
        'Mar Doce Supermercados',
      );
    });

    test('sigla sem vogal continua em maiúsculas', () {
      expect(
        MerchantName.pretty('WNS SUPERMERCADOS DO BRASIL LTDA'),
        'WNS Supermercados do Brasil',
      );
    });

    test('nome já escrito normalmente não é mexido', () {
      expect(MerchantName.pretty('Padaria Pão Quente'), 'Padaria Pão Quente');
    });

    test('sem nome, nada', () {
      expect(MerchantName.pretty('   '), isNull);
      expect(MerchantName.pretty(null), isNull);
    });
  });

  group('texto em forma de leitura', () {
    test('tira coluna, ruído e cola o item cortado na linha dele', () {
      const raw =
          'MAR DOCE SUPERMERCADOS LTDA\n'
          '-----------------------\n'
          'AR085019 MILHO VERDE BONARE\n'
          'bco gd pvc\n'
          '   \n'
          r'Valor a Pagar     R$    653,58';

      expect(ReceiptLayout.lines(raw), [
        'MAR DOCE SUPERMERCADOS LTDA',
        'AR085019 MILHO VERDE BONARE bco gd pvc',
        r'Valor a Pagar R$ 653,58',
      ]);
    });

    test('a ordem é a do papel: nada é reordenado nem inventado', () {
      final lines = ReceiptLayout.lines(storeReceiptText);

      expect(lines.first, 'MAR DOCE SUPERMERCADOS LTDA');
      expect(lines, contains(r'Valor a Pagar R$ 653,58'));
      expect(lines.length, lessThan(storeReceiptText.split('\n').length + 1));
    });
  });

  group('categoria pelo ramo', () {
    Future<EntryProposal> classify(String text) =>
        const RuleBasedClassifier().classify(
          ClassificationRequest(
            text: text,
            categories: const [
              Category(
                id: 'groceries',
                name: 'Mercado',
                block: Block.variable,
                groupId: 'food',
              ),
            ],
            today: _today,
            categoryByMerchantKind: const {
              MerchantKind.supermarket: 'groceries',
            },
          ),
        );

    test(
      'cupom de supermercado nasce como compra de mercado, na zona média',
      () async {
        final proposal = await classify(storeReceiptText);

        expect(proposal.category.candidates, ['groceries']);
        expect(proposal.category.confidence, Confidence.medium);
        expect(proposal.category.source, FieldSource.fixedRule);
      },
    );

    test('ramo que o cadastro não mapeia fica sem categoria', () async {
      final proposal = await classify(r'PADARIA PAO QUENTE\nTotal R$ 9,90');

      expect(proposal.category.confidence, Confidence.low);
    });
  });
}
