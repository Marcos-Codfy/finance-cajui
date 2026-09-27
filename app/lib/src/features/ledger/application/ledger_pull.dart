import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_downlink.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:domain/domain.dart';

/// Traz para este aparelho o que os outros fizeram (BL-062).
///
/// Lê o que o servidor tem, compara com o livro daqui e grava **só a
/// diferença**, como fatos locais comuns — o registro deste aparelho não
/// sabe que eles vieram de fora, e não precisa saber. Cada fato leva uma
/// chave que nasce do conteúdo: trazer a mesma coisa duas vezes grava uma.
///
/// Quem manda em cada conflito:
///
/// - **Lançamento**: vale a versão do servidor, que é a última a chegar
///   lá. Entre dois celulares do mesmo dono, "o que sincronizou por último"
///   é a regra mais previsível que existe.
/// - **Plano do mês**: vale o mais novo pelo carimbo de quando foi editado,
///   e não pelo que chegou por último — quem sincroniza tarde não apaga o
///   que o outro editou antes.
/// - **Cancelamento**: o que um cancelou, os outros cancelam. Nunca o
///   contrário: nada aqui recria o que o servidor diz que morreu.
final class LedgerPull {
  /// Cria a descida sobre [downlink], gravando cada fato por [absorb].
  const new(this.downlink, {required this.clock, required this.absorb});

  /// De onde o livro desce.
  final LedgerDownlink downlink;

  /// De onde vem o dia de hoje.
  final Clock clock;

  /// Grava um fato no livro deste aparelho **sem** disparar nova subida:
  /// o que veio do servidor não precisa voltar para ele.
  final Future<void> Function(LedgerEvent event) absorb;

  /// Traz o que falta em [book]. Devolve quantos fatos entraram.
  Future<int> run(LedgerBook book) async {
    final snapshot = await downlink.snapshot();
    if (snapshot == null) return 0;
    var received = 0;
    for (final event in _missingIn(book, snapshot)) {
      await absorb(event);
      received++;
    }
    return received;
  }

  Iterable<LedgerEvent> _missingIn(
    LedgerBook book,
    LedgerSnapshot snapshot,
  ) sync* {
    for (final event in snapshot.events) {
      final missing = _missingEvent(book, snapshot, event);
      if (missing != null) yield missing;
    }
    // O que outro aparelho cancelou e este ainda mostra.
    for (final id in snapshot.cancelled) {
      if (book.entryOf(id) == null) continue;
      yield EntryCancelled(
        id: 'cancellation-sync-$id',
        entryId: id,
        on: clock.today(),
        reason: 'cancelado em outro aparelho',
      );
    }
  }

  LedgerEvent? _missingEvent(
    LedgerBook book,
    LedgerSnapshot snapshot,
    LedgerEvent event,
  ) => switch (event) {
    EntryRecorded(:final entry) => _entry(book, snapshot, entry),
    PlanDefined(:final setup) => _plan(book, setup),
    CardDefined(:final card) =>
      book.cardOf(card.id) == null
          ? CardDefined(id: 'card-sync-${card.id}', card: card)
          : null,
    IncomeReceived(:final receipt) =>
      book.receipts.any((r) => r.id == receipt.id) ? null : event,
    VoucherBalanceAdjusted(:final adjustment) =>
      book.voucherAdjustments.any((a) => a.id == adjustment.id) ? null : event,
    EntryReversed(:final reversal) =>
      book.reversals.any((r) => r.id == reversal.id) ? null : event,
    // O resto — correção, cancelamento, fechamento, dívida — não desce do
    // servidor como fato: o servidor guarda o lançamento como ficou, e é
    // isso que se compara.
    _ => null,
  };

  /// Lançamento que este aparelho não tem entra; o que tem diferente é
  /// corrigido para a versão do servidor — a menos que a daqui seja mais
  /// nova pelo carimbo: aí é ela que sobe, e a do servidor não desce por
  /// cima. O que o servidor já cancelou não volta por aqui de jeito nenhum.
  LedgerEvent? _entry(LedgerBook book, LedgerSnapshot snapshot, Entry entry) {
    if (snapshot.cancelled.contains(entry.id)) return null;
    final local = book.entryOf(entry.id);
    if (local == null) return EntryRecorded(entry);
    final theirs = _signatureOf(entry);
    if (_signatureOf(local) == theirs) return null;
    if (local.isNewerThan(entry)) return null;
    return EntryCorrected(
      // A chave nasce do conteúdo: a mesma versão vinda duas vezes grava
      // uma, e uma versão nova grava outra.
      id: 'correction-sync-${entry.id}-${theirs.hashCode.toRadixString(16)}',
      entry: entry,
      on: clock.today(),
      reason: 'corrigido em outro aparelho',
    );
  }

  /// O plano só desce quando é mais novo que o daqui, pelo carimbo.
  LedgerEvent? _plan(LedgerBook book, MonthSetup setup) {
    if (!setup.isNewerThan(book.setup)) return null;
    final at = setup.definedAt?.millisecondsSinceEpoch ?? 0;
    return PlanDefined(id: 'plan-sync-$at', setup: setup);
  }

  /// A mesma assinatura da subida: tudo o que no lançamento é conteúdo.
  static String _signatureOf(Entry entry) =>
      LedgerUplink.signatureOf(EntryCodec.fromEntry(entry));
}
