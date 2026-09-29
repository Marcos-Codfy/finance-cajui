import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:meta/meta.dart';

/// O que a sincronização precisa saber **além** do estado do livro.
///
/// O livro mostra como as coisas estão; para conversar com o servidor é
/// preciso saber também como chegaram a estar. São duas coisas, e nenhuma
/// delas aparece em tela:
///
/// - o que foi **cancelado neste aparelho**: só isso é cancelado no servidor.
///   "O servidor tem e eu não" também descreve o que ainda não desceu, e
///   cancelar isso apagaria o que o outro aparelho acabou de lançar
///   (BL-062);
/// - os **fatos que sobem como estão** — fatura paga, dívida, parcela de
///   dívida paga, mês fechado —, inteiros e na ordem: é pelo identificador
///   de cada um que se sabe o que falta lá (ADR-019).
@immutable
final class SyncTrail {
  /// Cria o rastro.
  const new({this.cancelledIds = const {}, this.facts = const []});

  /// Os lançamentos cancelados neste aparelho (RN-208).
  final Set<String> cancelledIds;

  /// Os fatos que sobem ao servidor como estão, na ordem em que entraram.
  final List<LedgerEvent> facts;

  /// Os identificadores de [facts].
  Set<String> get factIds => {for (final fact in facts) fact.id};

  /// O mesmo rastro com o lançamento [entryId] cancelado aqui.
  SyncTrail cancelling(String entryId) =>
      SyncTrail(cancelledIds: {...cancelledIds, entryId}, facts: facts);

  /// O mesmo rastro com [fact] guardado.
  SyncTrail keeping(LedgerEvent fact) =>
      SyncTrail(cancelledIds: cancelledIds, facts: [...facts, fact]);
}
