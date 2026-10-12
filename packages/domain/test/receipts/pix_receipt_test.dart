import 'package:domain/domain.dart';
import 'package:test/test.dart';

import '../support/pix_receipt.dart';

/// O comprovante de Pix de um banco digital, no formato em que ele sai de
/// verdade. Cada caso aqui nasceu de um campo que o leitor errava.
void main() {
  final today = LocalDate(2026, 9, 21);
  final text = ReceiptText.clean(pixReceiptText);

  group('RN-752 · leitura de um Pix de banco digital', () {
    test('RN-753 · o valor está na linha de baixo do rótulo "Valor"', () {
      expect(ReceiptFieldReader.amountCandidates(text), [
        const Money.fromCents(600),
      ]);
    });

    test('a data vem com o mês por extenso: 12/set/2026', () {
      expect(
        ReceiptFieldReader.dateIn(text, today: today),
        LocalDate(2026, 9, 12),
      );
    });

    test('outras escritas de mês por extenso também são lidas', () {
      for (final written in ['12 de setembro de 2026', '12 SET 2026']) {
        expect(
          ReceiptFieldReader.dateIn('Pago em $written', today: today),
          LocalDate(2026, 9, 12),
          reason: written,
        );
      }
    });

    test('RN-746 · mês por extenso no futuro também deixa o campo vazio', () {
      expect(ReceiptFieldReader.dateIn('30/dez/2026', today: today), isNull);
      expect(ReceiptFieldReader.dateIn('31/fev/2026', today: today), isNull);
    });

    test('o recebedor é o bloco depois de "Para", até o documento', () {
      expect(
        MerchantReader.nameIn(text),
        'LANCHONETE E RESTAURANTE SABOR DA PRACA',
      );
    });

    test('rótulo solto nunca vira estabelecimento', () {
      const cut = 'Comprovante de Pix\nValor\nR\$ 6,00\nPADARIA CENTRAL';

      expect(MerchantReader.nameIn(cut), 'PADARIA CENTRAL');
    });

    test('RN-754 · é Pix, mesmo com "CRÉDITO" no nome da cooperativa', () {
      expect(ReceiptFieldReader.paymentKindIn(text), PaymentMethodKind.pix);
    });

    test('a proposta inteira sai das regras, sem rede (RN-780)', () async {
      final proposal = await const RuleBasedClassifier().classify(
        ClassificationRequest(text: text, categories: const [], today: today),
      );

      expect(proposal.documentKind.value, DocumentKind.purchase);
      expect(proposal.amount.value, const Money.fromCents(600));
      expect(proposal.occurredOn.value, LocalDate(2026, 9, 12));
      expect(proposal.paymentKind.value, PaymentMethodKind.pix);
      expect(proposal.category.confidence, Confidence.low);
    });
  });

  group('RN-731 · mascaramento de um Pix de banco digital', () {
    final redacted = PiiRedactor.redact(text);

    test('CPF meio mascarado e sem hífen ainda é dado pessoal', () {
      expect(redacted, isNot(contains('123.456')));
      expect(redacted, contains('[CPF]'));
    });

    // Antes as duas linhas viravam um [NOME] só. O extrato vai à IA com as
    // linhas numeradas (RN-1106), e juntar linhas deslocaria a numeração:
    // agora cada linha do nome vira o seu marcador.
    test('RN-732 · o nome do pagador, em duas linhas, vira [NOME] linha a '
        'linha', () {
      expect(redacted, isNot(contains('FULANO')));
      expect(redacted, isNot(contains('DA SILVA')));
      expect(redacted, contains('De\n[NOME]\n[NOME]\n[CPF]'));
    });

    test('RN-1106 · o texto mascarado tem o mesmo número de linhas', () {
      expect(redacted.split('\n'), hasLength(text.split('\n').length));
    });

    test('RN-734 · o estabelecimento, ligado a CNPJ, fica', () {
      expect(redacted, contains('LANCHONETE E\nRESTAURANTE SABOR DA\nPRACA'));
      expect(redacted, contains('[CNPJ]'));
    });

    test('identificadores da transação não saem do aparelho', () {
      expect(redacted, isNot(contains('E00000000202609121118')));
      expect(redacted, isNot(contains('2345678901234567')));
    });

    test('valor, data e forma de pagamento continuam legíveis', () {
      expect(redacted, contains(r'R$ 6,00'));
      expect(redacted, contains('12/set/2026'));
      expect(redacted, contains('Pix'));
    });
  });
}
