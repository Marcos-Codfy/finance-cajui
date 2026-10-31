import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/features/debts/application/debts_service.dart';
import 'package:cajui/src/features/debts/presentation/debt_form_state.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O que a tela de cadastro entrega para gravar: o que a pessoa preencheu,
/// sem conta nenhuma. `byBalance` diz se a dívida se mede pelo saldo (conta
/// atrasada, rotativo) ou em parcelas; a tela já sabe, porque é ela que decide
/// quais campos mostrar.
typedef DebtDraft = ({
  String creditor,
  DebtKind kind,
  bool byBalance,
  int amountCents,
  int balanceCents,
  int totalInstallments,
  int paidInstallments,
  int dueDay,
  bool nextIsThisMonth,
  String? note,
});

/// O ViewModel do cadastro de dívida (ADR-002).
///
/// Cuida de **gravar**: escolhe entre a dívida em parcelas e a dívida por
/// saldo, pede ao caso de uso e transforma a recusa de uma regra no erro do
/// catálogo. A tela só desenha os campos e escuta o estado.
class DebtFormViewModel extends Notifier<DebtFormState> {
  @override
  DebtFormState build() => const DebtFormEditing();

  /// Grava a dívida. Recusa de regra vira o aviso do catálogo; sucesso fecha.
  Future<void> save(DebtDraft draft) async {
    if (state is DebtFormSaving) return;
    state = const DebtFormSaving();
    final result = await _define(draft);
    state = switch (result) {
      Ok() => const DebtFormSaved(),
      Err(:final failure) => DebtFormEditing(
        problem: FailurePresenter.present(failure),
      ),
    };
  }

  /// Dispensa o aviso: mexer no formulário é começar a resolver o problema.
  void dismissProblem() => state = const DebtFormEditing();

  Future<Result<Debt>> _define(DebtDraft draft) {
    final service = ref.read(debtsServiceProvider);
    // Vale nos dois tipos: a observação da parcelada era descartada.
    final note = draft.note?.trim();
    final cleanNote = note == null || note.isEmpty ? null : note;
    if (draft.byBalance) {
      return service.defineByBalance(
        creditor: draft.creditor,
        kind: draft.kind,
        balance: Money.fromCents(draft.balanceCents),
        monthlyPayment: Money.fromCents(draft.amountCents),
        dueDay: draft.dueDay,
        note: cleanNote,
      );
    }
    return service.define(
      creditor: draft.creditor,
      kind: draft.kind,
      installmentAmount: Money.fromCents(draft.amountCents),
      totalInstallments: draft.totalInstallments,
      paidInstallments: draft.paidInstallments,
      dueDay: draft.dueDay,
      firstMonth: _firstMonth(draft),
      note: cleanNote,
    );
  }

  /// O mês da primeira parcela, contando para trás a partir da próxima: é o
  /// que o domínio precisa para projetar a quitação (RN-531).
  BudgetMonth _firstMonth(DebtDraft draft) {
    final today = ref.read(clockProvider).today().budgetMonth;
    final next = draft.nextIsThisMonth ? today : today.next;
    return next.addMonths(-draft.paidInstallments);
  }
}

/// O ViewModel do cadastro de dívida. Descartado ao fechar a tela: cada
/// abertura começa sem recusa nenhuma.
final NotifierProvider<DebtFormViewModel, DebtFormState> debtFormProvider =
    NotifierProvider.autoDispose(DebtFormViewModel.new);
