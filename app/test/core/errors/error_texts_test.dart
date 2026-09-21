import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_text.dart';
import 'package:cajui/src/core/errors/error_texts.g.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// A coluna "Texto" do catálogo, por código.
Map<String, String> _catalogTexts() {
  final row = RegExp(r'^\| `(E-[A-Z]+-\d\d)`[^|]*\|[^|]+\|[^|]+\|([^|]+)\|');
  final file = File('../docs/spec/error-catalog.md');
  return {
    for (final line in file.readAsLinesSync())
      if (row.firstMatch(line) case final match?)
        match.group(1)!: match.group(2)!.trim(),
  };
}

/// Erro que não precisa de botão: o de campo, cuja saída é o próprio campo,
/// e o de espera, em que só resta a contagem.
bool _needsNoAction(ErrorCode code, ErrorText text) =>
    code.errorClass == ErrorClass.validation ||
    text.placeholders.contains('segundos');

void main() {
  group('textos do catálogo de erros (ADR-015)', () {
    test('cada código tem o texto que está no catálogo', () {
      final catalog = _catalogTexts();

      expect(catalog, hasLength(ErrorCode.values.length));
      for (final code in ErrorCode.values) {
        expect(
          ErrorTexts.of(code).message,
          catalog[code.code],
          reason: code.code,
        );
      }
    });

    test('todo erro oferece uma saída, salvo o de campo e o de espera', () {
      for (final code in ErrorCode.values) {
        final text = ErrorTexts.of(code);

        expect(
          text.actions.isNotEmpty || _needsNoAction(code, text),
          isTrue,
          reason: code.code,
        );
      }
    });

    test('RN-944 · nenhum texto usa termo que o guia de voz reprova', () {
      for (final code in ErrorCode.values) {
        final text = ErrorTexts.of(code);
        final all = [text.message, ...text.actions].join(' ');

        expect(VoiceGuide.violations(all), isEmpty, reason: code.code);
      }
    });

    test('botão diz o que acontece em até cinco palavras', () {
      for (final code in ErrorCode.values) {
        for (final action in ErrorTexts.of(code).actions) {
          expect(
            action.split(' ').length,
            lessThanOrEqualTo(5),
            reason: action,
          );
        }
      }
    });
  });

  group('ErrorText', () {
    const text = ErrorText(
      'O vale tem {saldo}, e esta compra é de {valor}.',
      actions: ['Pagar {saldo} no vale'],
    );

    test('lista as chaves que a frase e as saídas pedem', () {
      expect(text.placeholders, {'saldo', 'valor'});
    });

    test('troca cada chave pelo valor, na frase e nas saídas', () {
      final filled = text.fill({'saldo': r'R$ 22,60', 'valor': r'R$ 38,40'});

      expect(
        filled.message,
        r'O vale tem R$ 22,60, e esta compra é de R$ 38,40.',
      );
      expect(filled.actions, [r'Pagar R$ 22,60 no vale']);
    });

    test('chave sem valor é defeito de quem chama', () {
      expect(() => text.fill({'saldo': 'x'}), throwsAssertionError);
    });
  });
}
