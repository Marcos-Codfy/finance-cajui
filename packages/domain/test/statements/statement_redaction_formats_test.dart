import 'package:domain/domain.dart';
import 'package:test/test.dart';

/// Páginas fictícias nos formatos que os bancos usam — reconstruídos de
/// exemplo, sem extrato real conferido. Nenhum nome, CPF ou valor é de
/// alguém.
void main() {
  group('RN-1106 · RN-732 · o nome nos formatos dos bancos vira [NOME]', () {
    test('Nubank: o nome na linha de baixo de "Transferência enviada pelo '
        'Pix", e o CPF com • inteiro', () {
      const page = [
        'Transferência enviada pelo Pix',
        'FULANO DE TAL - •••.123.456-•• - BANCO EXEMPLO',
        '150,00',
      ];

      final redacted = PiiRedactor.redactLines(page);

      expect(redacted, [
        'Transferência enviada pelo Pix',
        '[NOME] - [CPF] - BANCO EXEMPLO',
        '150,00',
      ]);
    });

    test('Inter: o nome entre aspas, depois do código da instituição', () {
      final redacted = PiiRedactor.redact(
        'Pix enviado: "Cp :60746948-FULANO DE TAL" 150,00',
      );

      expect(redacted, 'Pix enviado: "Cp :60746948-[NOME]" 150,00');
    });

    test('TED com banco e agência antes do nome', () {
      expect(
        PiiRedactor.redact('TED 237 0001 JOAO SILVA 300,00'),
        'TED 237 0001 [NOME] 300,00',
      );
    });

    test('linha com quebra dentro: cada linha vai sozinha, e o nome de '
        'baixo ainda é achado', () {
      final redacted = PiiRedactor.redactLines(const [
        'Transferência enviada pelo Pix',
        'FULANO DE TAL',
        'RUIDO\nDO OCR',
      ]);

      expect(redacted, hasLength(3));
      expect(redacted[1], '[NOME]');
    });
  });

  group('RN-731 · RN-732 · CPF meio mascarado vira [CPF] inteiro', () {
    test('os seis dígitos do meio nunca saem, com *, •, x ou X nas '
        'pontas', () {
      for (final cpf in [
        '***.123.456-**',
        '•••.123.456-••',
        'xxx.123.456-xx',
        'XXX.123.456-XX',
        '•••123456••',
      ]) {
        final redacted = PiiRedactor.redact('CPF $cpf');

        expect(redacted, 'CPF [CPF]', reason: cpf);
      }
    });
  });

  group('RN-731 · a linha de saldo não leva o valor', () {
    test('"S A L D O" espaçado', () {
      final redacted = PiiRedactor.redact('S A L D O 1.234,56');

      expect(redacted, isNot(contains('1.234,56')));
      expect(redacted, contains('[SALDO]'));
    });

    test('saldo com a data entre o rótulo e o valor', () {
      final redacted = PiiRedactor.redactLines(const [
        'SALDO ANTERIOR EM 30/09 1.234,56',
        r'SALDO DO DIA 05/10 R$ 2.000,00',
        '05/10 SALDO DISPONÍVEL 05/10 -350,00',
        '05/10 PADARIA BOA VISTA 12,50',
      ]);

      expect(redacted, [
        'SALDO ANTERIOR EM 30/09 [SALDO]',
        'SALDO DO DIA 05/10 [SALDO]',
        '05/10 SALDO DISPONÍVEL 05/10 [SALDO]',
        '05/10 PADARIA BOA VISTA 12,50',
      ]);
    });
  });
}
