import 'dart:async';

import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_texts.g.dart';
import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_state.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O ViewModel da tela de lançar à mão (ADR-002).
///
/// Guarda o rascunho, pede a gravação ao caso de uso e transforma a recusa de
/// uma regra no erro do catálogo. Não valida nada por conta própria: a regra
/// é do domínio, e a tela só mostra o que ele respondeu.
class EntryFormViewModel extends Notifier<EntryFormState> {
  @override
  EntryFormState build() => EntryFormEditing(
    ref.watch(initialDraftProvider) ??
        EntryDraft(occurredOn: ref.read(clockProvider).today()),
  );

  EntryDraft get _draft => state.draft;

  /// Troca o rascunho. Mexer no formulário é começar a resolver o problema,
  /// então o aviso sai; se continuar errado, volta na próxima tentativa.
  void edit(EntryDraft Function(EntryDraft draft) change) {
    if (state is EntryFormSaving) return;
    state = EntryFormEditing(change(_draft));
  }

  /// Divide o pagamento em duas formas, ou volta a uma só (RN-204).
  ///
  /// Se a primeira forma é o vale, ela começa pagando o que o saldo cobre, e
  /// o resto vai para a segunda — a proposta da RN-122.
  Future<void> toggleSplit() async {
    if (_draft.isSplit) return edit((draft) => draft.copyWith(isSplit: false));
    final book = await ref.read(ledgerProvider.future);
    final total = Money.fromCents(_draft.amountCents);
    final usesVoucher = _draft.method?.tender == Tender.mealVoucher;
    final first = usesVoucher ? book.voucher.coverableFor(total) : total;
    edit(
      (draft) => draft.copyWith(
        isSplit: true,
        firstCents: first.cents,
        secondCents: (total - first).cents,
      ),
    );
  }

  /// Tenta gravar. Recusa de regra vira o aviso do catálogo; sucesso fecha.
  Future<void> submit() async {
    final draft = _draft;
    if (!draft.isComplete || state is EntryFormSaving) return;
    state = EntryFormSaving(draft);
    try {
      final ledger = ref.read(ledgerProvider.notifier);
      // O mesmo formulário lança e corrige: o rascunho sabe qual dos dois.
      final result = await (draft.correctionOf == null
          ? ledger.record(draft)
          : ledger.correct(draft));
      state = _after(draft, result);
      // Falha que não é de regra — disco cheio, defeito do próprio app. A tela
      // não pode ficar presa em "gravando": volta a editar, com o que foi
      // digitado intacto, e diz que nada foi gravado.
    } on Object catch (error, stack) {
      state = EntryFormEditing(draft, problem: _unexpected);
      Zone.current.handleUncaughtError(error, stack);
    }
  }

  EntryFormState _after(EntryDraft draft, Result<Entry> result) {
    return switch (result) {
      Ok(:final value) => EntryFormSaved(draft, value),
      Err(:final failure) => EntryFormEditing(
        draft,
        problem: FailurePresenter.present(
          failure,
          names: {'forma': (draft.secondMethod ?? draft.method)?.name ?? ''},
        ),
      ),
    };
  }

  /// O erro sem nome do catálogo. Este lançamento não entrou em fila nenhuma,
  /// então a frase termina em "continua salvo", sem complemento.
  static final PresentedError _unexpected = (
    code: ErrorCode.app01,
    text: ErrorTexts.of(ErrorCode.app01).fill(const {'fila': ''}),
  );

  /// Executa a saída de índice [action] do aviso em tela. Cada código do
  /// catálogo tem as suas; o que não muda o rascunho só dispensa o aviso.
  Future<void> resolve(ErrorCode code, int action) async {
    final today = ref.read(clockProvider).today();
    switch ((code, action)) {
      case (ErrorCode.entry02, 0):
        edit((d) => d.copyWith(occurredOn: today));
      case (ErrorCode.entry01, 1):
        edit((d) => d.copyWith(secondCents: d.amountCents - d.firstCents));
      case (ErrorCode.voucher01, 0):
        await _splitAroundVoucher();
      case (ErrorCode.voucher01, 1) || (ErrorCode.voucher02, 0):
        edit((d) => d.without(method: true));
      case (ErrorCode.voucher02, 1):
        edit((d) => d.without(category: true));
      default:
        edit((d) => d);
    }
  }

  /// Refaz a divisão com o vale na frente, pagando o que o saldo cobre.
  ///
  /// Com o vale zerado não há o que dividir: uma linha de R$ 0,00 só trocaria
  /// um aviso por outro. Nesse caso a saída é escolher outra forma.
  Future<void> _splitAroundVoucher() async {
    final book = await ref.read(ledgerProvider.future);
    if (book.voucher.balance.isZero) {
      edit((draft) => draft.without(method: true));
      return;
    }
    final voucherIsSecond = _draft.secondMethod?.tender == Tender.mealVoucher;
    edit((d) => (voucherIsSecond ? d.swapped : d).copyWith(isSplit: false));
    await toggleSplit();
  }
}

/// O ViewModel da tela de lançar. Descartado ao fechar a tela: cada abertura
/// começa de um rascunho em branco.
final NotifierProvider<EntryFormViewModel, EntryFormState> entryFormProvider =
    NotifierProvider.autoDispose(
      EntryFormViewModel.new,
      dependencies: [initialDraftProvider],
    );

/// O rascunho com que o formulário abre. Em branco por padrão; a conferência
/// de um comprovante o troca, no próprio escopo, pelo que a leitura propôs.
final initialDraftProvider = Provider<EntryDraft?>(
  (ref) => null,
  dependencies: const [],
);
