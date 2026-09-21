import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const _coupon = r'''
MERCADO BOA COMPRA LTDA 0042
CNPJ 12.345.678/0001-90
ARROZ 5KG            28,90
SUBTOTAL            190,40
DESCONTO              4,00
TOTAL R$           186,40
CREDITO A VISTA **** 4821
12/09/2026 15:04''';

const _pix = r'''
Comprovante de Pix
Valor: R$ 1.100,00
Destinatário: João P. Silva
CPF: ***.456.789-**
Chave Pix: joao.silva@email.com
Pagador: Marcos Vinicius
Ag 1234 Cc 56789-0
ID da transação: E12345678202609121504abcDEF123
Saldo disponível R$ 3.412,77
10/09/2026''';

ClassificationRequest _request(
  String text, {
  Map<String, String> learned = const {},
}) => ClassificationRequest(
  text: ReceiptText.clean(text),
  categories: const [groceries, leisure],
  today: today,
  learnedRules: learned,
);

void main() {
  group('ReceiptText', () {
    test('INJ-05 tira caractere invisível e corta o enchimento', () {
      final hidden = 'TOTAL 10,00${String.fromCharCodes([0x202E, 0x200B])}xyz';
      final padded = '$hidden\n${'a' * 1000000}';

      final cleaned = ReceiptText.clean(padded);

      expect(cleaned, startsWith('TOTAL 10,00xyz'));
      expect(cleaned.length, ReceiptText.maxLength);
    });
  });

  group('PiiRedactor', () {
    final redacted = PiiRedactor.redact(_pix);

    test('RN-731 cada dado vira o seu marcador, sem sobrar conteúdo', () {
      for (final secret in [
        '456.789',
        'joao.silva@email.com',
        '56789-0',
        'E12345678202609121504abcDEF123',
        '3.412,77',
        'Marcos Vinicius',
      ]) {
        expect(redacted, isNot(contains(secret)), reason: secret);
      }
      expect(redacted, contains('[CPF]'));
      expect(redacted, contains('[CHAVE_PIX]'));
      expect(redacted, contains('[CONTA]'));
      expect(redacted, contains('[ID]'));
      expect(redacted, contains('[SALDO]'));
    });

    test('RN-732 nome ligado a CPF é mascarado; ligado a CNPJ, fica', () {
      const shop =
          'Destinatário: MERCADO BOA COMPRA LTDA\nCNPJ 12.345.678/0001-90';

      expect(redacted, contains('Destinatário: [NOME]'));
      expect(PiiRedactor.redact(shop), contains('MERCADO BOA COMPRA'));
      expect(PiiRedactor.redact(shop), contains('[CNPJ]'));
    });

    test('RN-734 valor, data e estabelecimento continuam legíveis', () {
      final coupon = PiiRedactor.redact(_coupon);

      expect(coupon, contains('MERCADO BOA COMPRA'));
      expect(coupon, contains('186,40'));
      expect(coupon, contains('12/09/2026'));
      expect(coupon, contains('[CARTAO]'));
      expect(coupon, isNot(contains('4821')));
    });

    test('RN-732 nome do domicílio é mascarado onde aparecer', () {
      final text = PiiRedactor.redact(
        'Recebido de MARCOS ARRUDA hoje',
        householdNames: ['Marcos Arruda'],
      );

      expect(text, 'Recebido de [NOME] hoje');
    });

    test('RN-733 entrada de pior caso termina dentro do prazo', () {
      final hostile = '${'1' * 40}.${'a@' * 30} ' * 100;
      final watch = Stopwatch()..start();

      PiiRedactor.redact(ReceiptText.clean(hostile));

      expect(watch.elapsedMilliseconds, lessThan(2000));
    });
  });

  group('ReceiptFieldReader', () {
    test(
      'RN-753 o valor é o do rótulo TOTAL; subtotal e desconto não contam',
      () {
        expect(ReceiptFieldReader.amountCandidates(_coupon), [
          const Money.fromCents(18640),
        ]);
      },
    );

    test('RN-753 sem rótulo, vêm os candidatos, do maior para o menor', () {
      const text = 'Padaria Central\n8,50\n2,00';

      expect(ReceiptFieldReader.amountCandidates(text).map((m) => m.cents), [
        850,
        200,
      ]);
    });

    test('RN-746 data no futuro deixa o campo vazio', () {
      expect(
        ReceiptFieldReader.dateIn('Data 03/10/2026', today: today),
        isNull,
      );
      expect(
        ReceiptFieldReader.dateIn(_coupon, today: today),
        LocalDate(2026, 9, 12),
      );
    });

    test('RN-754 e RN-755 forma de pagamento e parcelas pelas palavras', () {
      expect(
        ReceiptFieldReader.paymentKindIn(_coupon),
        PaymentMethodKind.creditCard,
      );
      expect(ReceiptFieldReader.paymentKindIn(_pix), PaymentMethodKind.pix);
      expect(ReceiptFieldReader.installmentsIn(r'10x de R$ 150,00'), 10);
      expect(ReceiptFieldReader.installmentsIn('PARC 01/06'), 6);
      expect(ReceiptFieldReader.installmentsIn(_coupon), isNull);
    });

    test(
      'RN-756 a 759 pagamento de fatura, recebimento e saque não são compra',
      () {
        expect(
          ReceiptFieldReader.documentKindIn(
            r'Pagamento de fatura — R$ 1.240,00',
          ),
          DocumentKind.statementPayment,
        );
        expect(
          ReceiptFieldReader.documentKindIn(r'Pix recebido R$ 2.310,00'),
          DocumentKind.incomeReceipt,
        );
        expect(
          ReceiptFieldReader.documentKindIn(r'Saque 24h R$ 100,00'),
          DocumentKind.ownTransfer,
        );
        expect(
          ReceiptFieldReader.documentKindIn(_coupon),
          DocumentKind.purchase,
        );
      },
    );

    test(
      'RN-727 o estabelecimento normalizado ignora loja, caixa e sufixo',
      () {
        final merchant = ReceiptFieldReader.merchantIn(_coupon)!;

        expect(PossibleDuplicate.normalize(merchant), 'mercado boa compra');
        expect(
          PossibleDuplicate.normalize('Mercado Boa-Compra'),
          'mercado boa compra',
        );
      },
    );
  });

  group('RuleBasedClassifier', () {
    const classifier = RuleBasedClassifier();

    test('RN-752 lê sozinho valor, data, pagamento e tipo, sem IA', () async {
      final proposal = await classifier.classify(_request(_coupon));

      expect(proposal.amount.value, const Money.fromCents(18640));
      expect(proposal.amount.confidence, Confidence.high);
      expect(proposal.occurredOn.value, LocalDate(2026, 9, 12));
      expect(proposal.paymentKind.value, PaymentMethodKind.creditCard);
      expect(proposal.documentKind.value, DocumentKind.purchase);
      expect(proposal.category.confidence, Confidence.low);
    });

    test('RN-765 regra aprendida propõe a categoria na zona alta', () async {
      final proposal = await classifier.classify(
        _request(_coupon, learned: {'mercado boa compra': 'groceries'}),
      );

      expect(proposal.category.value, 'groceries');
      expect(proposal.category.source, FieldSource.learnedRule);
    });

    test('RN-767 regra que aponta para categoria removida não vale', () async {
      final proposal = await classifier.classify(
        _request(_coupon, learned: {'mercado boa compra': 'apagada'}),
      );

      expect(proposal.category.confidence, Confidence.low);
    });

    test('RN-744 mais de um valor possível vai para a zona média', () async {
      final proposal = await classifier.classify(
        _request('Padaria Central\n8,50\n2,00'),
      );

      expect(proposal.amount.value, isNull);
      expect(proposal.amount.confidence, Confidence.medium);
      expect(proposal.amount.candidates, hasLength(2));
    });
  });
}
