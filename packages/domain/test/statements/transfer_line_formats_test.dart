import 'package:domain/domain.dart';
import 'package:test/test.dart';

/// Linhas fictícias nos formatos que os bancos usam — reconstruídos de
/// exemplo, sem extrato real conferido. Nenhum nome, CPF ou valor é de
/// alguém.
void main() {
  group('RN-1106 · o nome depois do que o banco põe entre ele e o '
      'marcador', () {
    test('Inter: aspas, "Cp :" e o código da instituição antes do '
        'nome', () {
      expect(
        TransferLine.personIn(
          'Pix enviado: "Cp :60746948-FULANO DE TAL" 150,00',
        ),
        'FULANO DE TAL',
      );
    });

    test('TED com o código do banco e a agência antes do nome', () {
      expect(
        TransferLine.personIn('TED 237 0001 JOAO SILVA 300,00'),
        'JOAO SILVA',
      );
    });

    test('data e hora entre o marcador e o nome', () {
      expect(
        TransferLine.personIn('PIX RECEBIDO 05/10 14:32 MARIA SOUZA 80,00'),
        'MARIA SOUZA',
      );
    });

    test('"pelo", "enviado" e "Pix" repetido são pulados', () {
      expect(
        TransferLine.personIn('Transferência enviada pelo Pix ANA LIMA 20,00'),
        'ANA LIMA',
      );
    });

    test('palavra do banco depois do nome fecha o nome', () {
      expect(
        TransferLine.personIn('PIX ENVIADO JOAO SILVA AGENDADO 50,00'),
        'JOAO SILVA',
      );
    });

    test('apóstrofo e ponto de abreviação ficam no nome', () {
      expect(
        TransferLine.personIn("PIX ENVIADO ANA D'AVILA 10,00"),
        "ANA D'AVILA",
      );
      expect(
        TransferLine.personIn('PIX ENVIADO JOAO P. SILVA 10,00'),
        'JOAO P. SILVA',
      );
    });

    test('vale o marcador que vem primeiro na linha', () {
      expect(
        TransferLine.personIn('PIX JOAO SILVA TRANSFERENCIA 10,00'),
        'JOAO SILVA',
      );
    });
  });

  group('RN-1106 · palavra do banco nunca forma uma pessoa', () {
    test('"Transferência enviada pelo Pix" não tem nome nenhum', () {
      expect(TransferLine.personIn('Transferência enviada pelo Pix'), isNull);
    });

    test('"pelo pix" e "enviado cp" não têm cara de gente', () {
      expect(TransferLine.isPersonName('pelo pix'), isFalse);
      expect(TransferLine.isPersonName('enviado cp'), isFalse);
      expect(TransferLine.isPersonName('joao p silva'), isTrue);
    });
  });

  group('RN-1106 · o nome na linha de baixo (peopleIn)', () {
    test('Nubank: "Transferência enviada pelo Pix" e o nome embaixo — o '
        'índice é o da linha do nome', () {
      final people = TransferLine.peopleIn(const [
        'Transferência enviada pelo Pix',
        'FULANO DE TAL - •••.123.456-•• - BANCO EXEMPLO',
        '150,00',
        '05/10 PIX ENVIADO JOAO P SILVA 20,00',
      ]);

      expect(people, {1: 'FULANO DE TAL', 3: 'JOAO P SILVA'});
    });

    test('a linha de baixo com valor não é nome', () {
      final people = TransferLine.peopleIn(const [
        'Transferência enviada pelo Pix',
        'FULANO DE TAL 150,00',
      ]);

      expect(people, isEmpty);
    });

    test('linha com nome de empresa, ou de compra por QR, não olha a de '
        'baixo', () {
      final people = TransferLine.peopleIn(const [
        'PIX ENVIADO MERCADO BOA VISTA LTDA',
        'FULANO DE TAL',
        'PIX QR CODE ESTATICO',
        'CICLANO DE TAL',
      ]);

      expect(people, isEmpty);
    });

    test('a última linha sem nome não procura além do fim', () {
      expect(TransferLine.peopleIn(const ['PIX ENVIADO 150,00']), isEmpty);
    });
  });

  group('RN-1110 · se a linha é transferência para alguém (isTransfer)', () {
    test('Pix, TED e transferência, inclusive para empresa', () {
      for (final line in [
        'PIX ENVIADO JOAO SILVA 150,00',
        'Transferência enviada pelo Pix',
        'TED 237 0001 JOAO SILVA 300,00',
        'PIX ENVIADO MERCADO BOA VISTA LTDA 89,90',
      ]) {
        expect(TransferLine.isTransfer(line), isTrue, reason: line);
      }
    });

    test('QR code, pagamento, saque, devolução e compra não são', () {
      for (final line in [
        'PIX QR CODE ESTATICO 25,00',
        'PAGAMENTO PIX PADARIA CENTRAL 12,00',
        'PIX SAQUE 100,00',
        'TED DEVOLVIDA 300,00',
        'COMPRA CARTAO PADARIA CENTRAL 9,00',
        'PIXAR ANIMATION STUDIOS',
      ]) {
        expect(TransferLine.isTransfer(line), isFalse, reason: line);
      }
    });
  });

  group('RN-1106 · a posição do nome não se perde com letra que cresce na '
      'maiúscula', () {
    test('ß vira SS em maiúscula: o nome continua o mesmo', () {
      expect(
        TransferLine.personIn('PIX ENVIADO JOAO GROßMANN 150,00'),
        'JOAO GROßMANN',
      );
    });

    test('ß antes do marcador não desloca o nome', () {
      expect(
        TransferLine.personIn('Großhandel PIX ENVIADO ANA LIMA 10,00'),
        'ANA LIMA',
      );
    });
  });
}
