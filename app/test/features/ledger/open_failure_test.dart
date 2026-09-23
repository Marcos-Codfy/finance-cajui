import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/open_failure.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_journal.dart';
import 'package:cajui/src/features/ledger/presentation/entries_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persistence/persistence.dart';

import '../../support/test_scope.dart';

/// Um livro que recusa abrir com a falha dada. É o que acontece no aparelho
/// quando o arquivo foi adulterado ou o disco encheu.
final class _BrokenJournal implements LedgerJournal {
  new(this.failure);

  final Exception failure;

  @override
  Future<List<LedgerEvent>> readAll() async => throw failure;

  @override
  Future<void> append(LedgerEvent event) async => throw failure;
}

Future<EntriesState> _stateFor(Exception failure) async {
  final scope = ProviderContainer(
    overrides: testOverrides(journal: _BrokenJournal(failure)),
  );
  addTearDown(scope.dispose);
  // O livro abre de forma assíncrona: sem esperar, a tela ainda está em
  // "carregando" e o teste mediria a espera, não a falha.
  scope.listen(ledgerProvider, (_, _) {}, fireImmediately: true);
  for (var i = 0; i < 40 && !scope.read(ledgerProvider).hasError; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  final state = scope.read(entriesStateProvider);
  return state;
}

void main() {
  group('BL-033 · por que o livro não abriu', () {
    test('cadeia quebrada é E-DATA-01, e não o erro genérico', () {
      expect(
        OpenFailure.codeOf(
          const LogIntegrityException(seq: 3, reason: 'hash não bate'),
        ),
        ErrorCode.data01,
      );
    });

    test('sem espaço é E-STORAGE-01', () {
      expect(
        OpenFailure.codeOf(const StorageFullException('/dados')),
        ErrorCode.storage01,
      );
    });

    test('o que não tem nome continua E-APP-01: é a rede de segurança', () {
      expect(OpenFailure.codeOf(StateError('qualquer')), ErrorCode.app01);
      expect(OpenFailure.codeOf(null), ErrorCode.app01);
    });

    test(
      'livro que não abre vira falha na tela, e não esqueleto para sempre: '
      'o estado para em AsyncLoading carregando o erro, nunca em AsyncError',
      () async {
        final state = await _stateFor(const StorageFullException('/dados'));

        expect(state, isA<EntriesFailed>());
        expect((state as EntriesFailed).code, ErrorCode.storage01);
      },
    );

    test('cadeia quebrada também chega à tela, com o seu código', () async {
      final state = await _stateFor(
        const LogIntegrityException(seq: 3, reason: 'hash não bate'),
      );

      expect((state as EntriesFailed).code, ErrorCode.data01);
    });
  });
}
