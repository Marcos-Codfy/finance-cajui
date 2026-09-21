import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('RN-775 · o único texto livre da IA que chega à tela', () {
    test('nome curto de compra passa, sem espaço sobrando', () {
      expect(
        ReceiptDescriptionPolicy.accepted('  Mercado Boa Compra  '),
        'Mercado Boa Compra',
      );
    });

    test('vazio e ausente não são descrição', () {
      expect(ReceiptDescriptionPolicy.accepted(null), isNull);
      expect(ReceiptDescriptionPolicy.accepted('   '), isNull);
    });

    test('contato, em qualquer escrita, não passa', () {
      for (final contact in [
        'Ligue 0800 123 4567 para regularizar',
        'Fale com (63) 99999-1234',
        'Acesse https://exemplo.com',
        'Promoção em loja.com.br',
        'Escreva para sac@loja.com',
        'Protocolo 2026091200017',
      ]) {
        expect(
          ReceiptDescriptionPolicy.accepted(contact),
          isNull,
          reason: contact,
        );
      }
    });

    test('mais de 60 caracteres ou mais de uma linha não passa', () {
      expect(ReceiptDescriptionPolicy.accepted('a' * 61), isNull);
      expect(ReceiptDescriptionPolicy.accepted('Mercado\nOutra linha'), isNull);
    });

    test('cara de credencial não passa', () {
      expect(ReceiptDescriptionPolicy.accepted('sk-123'), isNull);
      expect(ReceiptDescriptionPolicy.accepted('token: abc'), isNull);
    });

    test('RN-944 · termo que o guia de voz reprova não passa', () {
      expect(ReceiptDescriptionPolicy.accepted('Você gastou demais'), isNull);
    });
  });
}
