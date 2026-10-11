import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:meta/meta.dart';

/// O que a sincronização precisa saber **além** do estado do livro.
///
/// O livro mostra como as coisas estão; para conversar com o servidor é
/// preciso saber também como chegaram a estar. São três coisas, e nenhuma
/// delas aparece em tela:
///
/// - o que foi **cancelado neste aparelho**: só isso é cancelado no servidor.
///   "O servidor tem e eu não" também descreve o que ainda não desceu, e
///   cancelar isso apagaria o que o outro aparelho acabou de lançar
///   (BL-062);
/// - os **fatos que sobem como estão** — fatura paga, dívida, parcela de
///   dívida paga, mês fechado —, inteiros e na ordem: é pelo identificador
///   de cada um que se sabe o que falta lá (ADR-019);
/// - **quando** a versão em vigor de cada cartão foi definida: é o que
///   decide entre dois celulares que editaram o mesmo cartão (ADR-024).
@immutable
final class SyncTrail {
  /// Cria o rastro.
  const new({
    this.cancelledIds = const {},
    this.facts = const [],
    this.cardStamps = const {},
  });

  /// Os lançamentos cancelados neste aparelho (RN-208).
  final Set<String> cancelledIds;

  /// Os fatos que sobem ao servidor como estão, na ordem em que entraram.
  final List<LedgerEvent> facts;

  /// O carimbo da versão em vigor de cada cartão, pelo identificador. Fica
  /// de fora o cartão gravado antes do carimbo existir.
  final Map<String, DateTime> cardStamps;

  /// Os identificadores de [facts].
  Set<String> get factIds => {for (final fact in facts) fact.id};

  /// O mesmo rastro com o lançamento [entryId] cancelado aqui.
  SyncTrail cancelling(String entryId) => SyncTrail(
    cancelledIds: {...cancelledIds, entryId},
    facts: facts,
    cardStamps: cardStamps,
  );

  /// O mesmo rastro com [fact] guardado.
  SyncTrail keeping(LedgerEvent fact) => SyncTrail(
    cancelledIds: cancelledIds,
    facts: [...facts, fact],
    cardStamps: cardStamps,
  );

  /// O carimbo de uma edição do cartão [cardId] feita agora, em [now].
  ///
  /// Nunca anterior ao da versão que este aparelho já tem: quem edita
  /// **depois** de ver a edição do outro celular está respondendo a ela, e
  /// a dele tem de valer — mesmo com o relógio daqui uns minutos atrasado,
  /// que de outro modo faria a edição sumir da tela no ato (BL-064).
  DateTime nextCardStamp(String cardId, DateTime now) {
    final current = cardStamps[cardId];
    if (current == null || now.isAfter(current)) return now;
    return current.add(const Duration(milliseconds: 1));
  }

  /// O mesmo rastro com a versão do cartão [cardId] carimbada em [at].
  SyncTrail stampingCard(String cardId, DateTime? at) => SyncTrail(
    cancelledIds: cancelledIds,
    facts: facts,
    cardStamps: at == null
        ? ({...cardStamps}..remove(cardId))
        : {...cardStamps, cardId: at},
  );
}
