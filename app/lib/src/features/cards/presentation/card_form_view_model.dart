import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/features/cards/presentation/card_form_state.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O que a tela de cadastro entrega para gravar. É o que a pessoa preencheu,
/// sem conta nenhuma: quem confere é o domínio (RN-302, `E-CARD-01`).
typedef CardDraft = ({
  String? id,
  String name,
  int closingDay,
  int dueDay,
  Money? creditLimit,
  String? skin,
});

/// O ViewModel do cadastro de cartão (ADR-002).
///
/// Cuida de **gravar**: pede ao caso de uso, segura o segundo toque e
/// transforma a recusa de uma regra na frase do catálogo. A tela só desenha os
/// campos e escuta o estado.
class CardFormViewModel extends Notifier<CardFormState> {
  @override
  CardFormState build() => const CardFormEditing();

  /// Grava o cartão. A trava existe porque o identificador é sorteado a cada
  /// chamada: dois toques em "Guardar" antes de a tela fechar cadastravam
  /// **dois cartões iguais**, e o segundo fechamento ainda derrubava a tela de
  /// trás junto.
  Future<void> save(CardDraft draft) async {
    if (state is CardFormSaving) return;
    state = const CardFormSaving();
    final result = await ref
        .read(ledgerProvider.notifier)
        .defineCard(
          id: draft.id,
          name: draft.name,
          closingDay: draft.closingDay,
          dueDay: draft.dueDay,
          creditLimit: draft.creditLimit,
          skin: draft.skin,
        );
    state = switch (result) {
      Ok() => const CardFormSaved(),
      Err(:final failure) => CardFormEditing(
        dayProblem: FailurePresenter.present(failure).text.message,
      ),
    };
  }
}

/// O ViewModel do cadastro de cartão. Descartado ao fechar a tela: cada
/// abertura começa sem recusa nenhuma.
final NotifierProvider<CardFormViewModel, CardFormState> cardFormProvider =
    NotifierProvider.autoDispose(CardFormViewModel.new);
