import 'dart:async';

import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/budget/application/income_service.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_journal.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_state.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_view_model.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_scope.dart';

final LedgerBook _book = DefaultCatalog.emptyBook;

/// O espaço que o formatador põe entre `R$` e o número.
const String _nbsp = BrlFormatter.nbsp;

/// Um livro que abre, mas não consegue gravar — disco cheio, por exemplo.
class _BrokenJournal implements LedgerJournal {
  @override
  Future<List<LedgerEvent>> readAll() async => const [];

  @override
  Future<void> append(LedgerEvent event) async =>
      throw StateError('sem espaço');
}

void main() {
  late ProviderContainer container;

  EntryFormViewModel form() => container.read(entryFormProvider.notifier);
  EntryFormState state() => container.read(entryFormProvider);
  EntryFormEditing editing() => state() as EntryFormEditing;

  /// Mercado de R$ 86,00 no vale, com R$ 30,00 de saldo.
  Future<void> groceriesOnVoucher() async {
    await container
        .read(incomeServiceProvider)
        .setVoucherBalance(const Money.fromCents(3000), reason: 'teste');
    form().edit(
      (d) => d.copyWith(
        amountCents: 8600,
        description: 'Mercado',
        category: _book.categoryOf('groceries'),
        method: _book.methodOf('voucher'),
      ),
    );
  }

  setUp(() {
    container = ProviderContainer(overrides: testOverrides());
    addTearDown(container.dispose);
    // Mantém o ViewModel vivo: ele é descartado quando ninguém o escuta.
    container.listen(entryFormProvider, (_, _) {});
  });

  test('nasce com a data de hoje e sem nada para resolver', () {
    expect(state().draft.occurredOn, testToday);
    expect(editing().problem, isNull);
    expect(state().draft.isComplete, isFalse);
  });

  test('RN-122 · dividir com o vale propõe o saldo todo no vale e o resto '
      'na outra forma', () async {
    await groceriesOnVoucher();

    await form().toggleSplit();

    expect(state().draft.isSplit, isTrue);
    expect(state().draft.firstCents, 3000);
    expect(state().draft.secondCents, 5600);
  });

  test('E-VOUCHER-01 · vale sem saldo para a compra: "Dividir o pagamento" '
      'monta a divisão', () async {
    await groceriesOnVoucher();

    await form().submit();
    final problem = editing().problem!;
    await form().resolve(problem.code, 0);

    expect(problem.code, ErrorCode.voucher01);
    expect(problem.text.message, contains('O vale tem R\$${_nbsp}30,00'));
    expect(state().draft.firstCents, 3000);
    expect(editing().problem, isNull);
  });

  test('E-VOUCHER-01 · com o vale zerado, "Dividir o pagamento" pede outra '
      'forma em vez de criar uma linha de zero', () async {
    form().edit(
      (d) => d.copyWith(
        amountCents: 8600,
        description: 'Mercado',
        category: _book.categoryOf('groceries'),
        method: _book.methodOf('voucher'),
      ),
    );

    await form().submit();
    await form().resolve(editing().problem!.code, 0);

    expect(state().draft.method, isNull);
    expect(state().draft.isSplit, isFalse);
    expect(state().draft.amountCents, 8600);
  });

  test('E-ENTRY-01 · 30 + 50 para 86: diz que faltam 6,00, e "Colocar o '
      'resto" fecha a conta', () async {
    await groceriesOnVoucher();
    await form().toggleSplit();
    form().edit(
      (d) => d.copyWith(secondMethod: _book.methodOf('pix'), secondCents: 5000),
    );

    await form().submit();
    final problem = editing().problem!;
    await form().resolve(problem.code, 1);

    expect(problem.code, ErrorCode.entry01);
    expect(problem.text.message, contains('Ajuste R\$${_nbsp}6,00'));
    expect(problem.text.actions.last, 'Colocar o resto em Pix');
    expect(state().draft.secondCents, 5600);
  });

  test('E-VOUCHER-02 · internet no vale: "Trocar a categoria" limpa a '
      'categoria e guarda o resto', () async {
    form().edit(
      (d) => d.copyWith(
        amountCents: 9990,
        description: 'Internet',
        category: _book.categoryOf('utilities'),
        method: _book.methodOf('voucher'),
      ),
    );

    await form().submit();
    final problem = editing().problem!;
    await form().resolve(problem.code, 1);

    expect(problem.code, ErrorCode.voucher02);
    expect(problem.text.message, contains('"Água, luz e internet"'));
    expect(state().draft.category, isNull);
    expect(state().draft.method, isNotNull);
  });

  test('E-ENTRY-02 · data futura: "Usar a data de hoje" corrige', () async {
    form().edit(
      (d) => d.copyWith(
        amountCents: 850,
        description: 'Ônibus',
        category: _book.categoryOf('transport'),
        method: _book.methodOf('pix'),
        occurredOn: testToday.addDays(1),
      ),
    );

    await form().submit();
    final problem = editing().problem!;
    await form().resolve(problem.code, 0);

    expect(problem.code, ErrorCode.entry02);
    expect(state().draft.occurredOn, testToday);
  });

  test('lançamento aceito termina em "gravado", com o lançamento', () async {
    form().edit(
      (d) => d.copyWith(
        amountCents: 850,
        description: '  Ônibus  ',
        category: _book.categoryOf('transport'),
        method: _book.methodOf('pix'),
      ),
    );

    await form().submit();

    final saved = state() as EntryFormSaved;
    expect(saved.entry.description, 'Ônibus');
    expect(saved.entry.amount.cents, 850);
  });

  test('E-APP-01 · falha que não é de regra devolve a tela à edição, com o '
      'que foi digitado e sem nada gravado', () async {
    final broken = ProviderContainer(
      overrides: testOverrides(journal: _BrokenJournal()),
    );
    addTearDown(broken.dispose);
    broken.listen(entryFormProvider, (_, _) {});
    final escaped = <Object>[];

    await runZonedGuarded(() async {
      final form = broken.read(entryFormProvider.notifier)
        ..edit(
          (d) => d.copyWith(
            amountCents: 850,
            description: 'Ônibus',
            category: _book.categoryOf('transport'),
            method: _book.methodOf('pix'),
          ),
        );
      await form.submit();
    }, (error, _) => escaped.add(error));

    final after = broken.read(entryFormProvider) as EntryFormEditing;
    expect(after.problem!.code, ErrorCode.app01);
    expect(after.problem!.text.message, endsWith('continua salvo.'));
    expect(after.draft.description, 'Ônibus');
    expect(escaped.single, isA<StateError>(), reason: 'o erro não é engolido');
  });

  test('rascunho incompleto não tenta gravar', () async {
    form().edit((d) => d.copyWith(amountCents: 850));

    await form().submit();

    expect(state(), isA<EntryFormEditing>());
    expect(editing().problem, isNull);
  });
}
