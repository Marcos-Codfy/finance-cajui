import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('RN-1106 · o nome da pessoa num Pix ou transferência', () {
    test('"PIX ENVIADO JOAO P SILVA 150,00": o nome, sem o valor', () {
      expect(
        TransferLine.personIn('PIX ENVIADO JOAO P SILVA 150,00'),
        'JOAO P SILVA',
      );
    });

    test('com "para", "de", acento, CPF ou data depois', () {
      expect(
        TransferLine.personIn(r'PIX RECEBIDO DE MARIA SOUZA 05/10 R$ 80,00'),
        'MARIA SOUZA',
      );
      expect(
        TransferLine.personIn('Transferência enviada para Ana Lima CPF ***'),
        'Ana Lima',
      );
      expect(
        TransferLine.personIn('TED - CARLOS DIAS 1.200,00'),
        'CARLOS DIAS',
      );
    });

    test('empresa não é pessoa: Pix para a loja é uma compra', () {
      expect(
        TransferLine.personIn('PIX ENVIADO MERCADO BOA VISTA LTDA'),
        isNull,
      );
      expect(TransferLine.personIn('PIX ENVIADO PADARIA CENTRAL'), isNull);
    });

    test('sem nome, ou só o primeiro nome, ou já mascarado: nada', () {
      expect(TransferLine.personIn('PIX ENVIADO [NOME] 150,00'), isNull);
      expect(TransferLine.personIn('PIX ENVIADO JOSE 30,00'), isNull);
      expect(TransferLine.personIn('COMPRA CARTAO PADARIA CENTRAL'), isNull);
    });

    test('as palavras do banco depois do marcador não são nome de ninguém', () {
      expect(TransferLine.personIn('PIX QR CODE ESTATICO 25,00'), isNull);
      expect(TransferLine.personIn('PIX AGENDADO CONTA LUZ'), isNull);
      expect(TransferLine.personIn('TED DEVOLVIDA 300,00'), isNull);
    });

    test('"PIX" dentro de outra palavra não é marcador', () {
      expect(TransferLine.personIn('PIXAR ANIMATION STUDIOS'), isNull);
    });
  });
}
