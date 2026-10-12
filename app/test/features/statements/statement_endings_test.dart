import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/statements/presentation/statement_endings.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// Os códigos que a leitura do extrato pode trazer: do arquivo, da rede, do
/// servidor e da IA. O E-AI-05 não é falha: é o aviso da página lida em
/// parte, que a abertura preenche com o número da página.
const List<ErrorCode> _reachable = [
  ErrorCode.capt01,
  ErrorCode.capt02,
  ErrorCode.net01,
  ErrorCode.net02,
  ErrorCode.auth03,
  ErrorCode.rate01,
  ErrorCode.srv01,
  ErrorCode.ai01,
  ErrorCode.ai02,
  ErrorCode.ai03,
  ErrorCode.ai04,
  ErrorCode.app01,
];

void main() {
  group('E-xxx · a falha do extrato fala pelo catálogo, inteira', () {
    for (final code in _reachable) {
      test('${code.code} não deixa marcador por preencher', () {
        final text = StatementEndings.textOf(
          code,
          month: const BudgetMonth(2026, 10),
        );

        expect(text, isNot(contains('{')));
        expect(text, isNot(contains('}')));
      });
    }

    test('E-APP-01 que para o lote no meio sai inteiro na fala final', () {
      final words = StatementEndings.doneWords((
        entries: const ['a', 'b'],
        incomes: const [],
        refused: const {},
        alreadyThere: 0,
        stopped: ErrorCode.app01,
      ));

      expect(words, isNot(contains('{')));
      expect(words, contains('O que estava salvo continua salvo.'));
    });

    test('E-AI-02 diz a espera de 60 segundos quando o serviço não diz', () {
      final text = StatementEndings.textOf(
        ErrorCode.ai02,
        month: const BudgetMonth(2026, 10),
      );

      expect(text, contains('60 segundos'));
    });
  });
}
