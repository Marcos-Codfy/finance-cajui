import 'package:cajui/src/features/debts/presentation/debt_form_state.dart';
import 'package:cajui/src/features/debts/presentation/debt_form_view_model.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_scope.dart';

DebtDraft _installments({int paid = 0, int total = 12, int amount = 15000}) => (
  creditor: 'Loja do Bairro',
  kind: DebtKind.loan,
  byBalance: false,
  amountCents: amount,
  balanceCents: 0,
  totalInstallments: total,
  paidInstallments: paid,
  dueDay: 10,
  nextIsThisMonth: true,
  note: null,
);

DebtDraft _byBalance({int balance = 90000, int payment = 0}) => (
  creditor: 'Conta atrasada',
  kind: DebtKind.overdueBill,
  byBalance: true,
  amountCents: payment,
  balanceCents: balance,
  totalInstallments: 0,
  paidInstallments: 0,
  dueDay: 10,
  nextIsThisMonth: true,
  note: '  combinado por mensagem  ',
);

void main() {
  late ProviderContainer container;

  DebtFormViewModel form() => container.read(debtFormProvider.notifier);
  DebtFormState state() => container.read(debtFormProvider);
  Future<List<Debt>> debts() async =>
      (await container.read(ledgerProvider.future)).debts;

  setUp(() {
    container = ProviderContainer(overrides: testOverrides());
    addTearDown(container.dispose);
    container.listen(debtFormProvider, (_, _) {});
  });

  test(
    'RN-501 · a dívida em parcelas é gravada, e a tela pode fechar',
    () async {
      await form().save(_installments());

      expect(state(), isA<DebtFormSaved>());
      final saved = (await debts()).single;
      expect(saved.creditor, 'Loja do Bairro');
      expect(saved.totalInstallments, 12);
    },
  );

  test('RN-1002 · a dívida por saldo pode nascer sem pagar nada por mês, e a '
      'observação sai sem as pontas', () async {
    await form().save(_byBalance());

    expect(state(), isA<DebtFormSaved>());
    expect((await debts()).single.note, 'combinado por mensagem');
  });

  test(
    'RN-531 · o mês da primeira parcela conta para trás as já pagas',
    () async {
      await form().save(_installments(paid: 3));

      final saved = (await debts()).single;
      expect(saved.firstMonth, testToday.budgetMonth.addMonths(-3));
    },
  );

  test('mais parcelas pagas que o total é recusado pelo domínio, com a frase '
      'do catálogo, e nada é gravado', () async {
    await form().save(_installments(paid: 13));

    final editing = state() as DebtFormEditing;
    expect(editing.problem, isNotNull);
    expect(await debts(), isEmpty);
  });

  test('dispensar o aviso volta a editar sem recusa', () async {
    await form().save(_installments(paid: 13));

    form().dismissProblem();

    expect((state() as DebtFormEditing).problem, isNull);
  });

  test('o segundo toque antes de gravar não cadastra outra dívida', () async {
    final first = form().save(_installments());
    final second = form().save(_installments());
    await Future.wait([first, second]);

    expect(await debts(), hasLength(1));
  });
}
