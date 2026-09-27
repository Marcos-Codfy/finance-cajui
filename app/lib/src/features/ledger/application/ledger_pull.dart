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
/// - **Lançamento**: vale a versão do servidor — a menos que a daqui seja
///   mais nova pelo carimbo de correção; aí é ela que sobe.
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

  /// Grava um fato no livro deste aparelho **sem** disparar nova subida, e
  /// diz se ele entrou — quem grava confere de novo, contra o livro em
  /// vigor, se o fato ainda faz diferença.
  final Future<bool> Function(LedgerEvent event) absorb;

  /// Traz o que falta em [book]. Devolve quantos fatos entraram.
  Future<int> run(LedgerBook book) async {
    final snapshot = await downlink.snapshot();
    if (snapshot == null) return 0;
    var received = 0;
    for (final event in _candidates(book, snapshot)) {
      if (await absorb(event)) received++;
    }
    return received;
  }

  /// Se [event], vindo do servidor, ainda muda alguma coisa em [book].
  ///
  /// É conferido **duas vezes**: ao montar a lista, contra o livro que a
  /// sincronização recebeu; e na hora de gravar, contra o livro em vigor.
  /// Entre uma coisa e outra, outra sincronização pode ter trazido o mesmo
  /// fato — duas descidas próximas contavam um lançamento em dobro —, ou a
  /// pessoa pode ter corrigido por cima.
  static bool accepts(LedgerBook book, LedgerEvent event) => switch (event) {
    // O que foi cancelado **aqui** não volta pela descida, nem quando o
    // cancelamento ainda não conseguiu subir: sumiria e reapareceria.
    EntryRecorded(:final entry) =>
      book.entryOf(entry.id) == null && !book.cancelledIds.contains(entry.id),
    EntryCorrected(:final entry) => switch (book.entryOf(entry.id)) {
      null => false,
      final local =>
        !local.isNewerThan(entry) && _signatureOf(local) != _signatureOf(entry),
    },
    EntryCancelled(:final entryId) => book.entryOf(entryId) != null,
    PlanDefined(:final setup) => setup.isNewerThan(book.setup),
    CardDefined(:final card) => book.cardOf(card.id) == null,
    IncomeReceived(:final receipt) => !book.receipts.any(
      (r) => r.id == receipt.id,
    ),
    VoucherBalanceAdjusted(:final adjustment) => !book.voucherAdjustments.any(
      (a) => a.id == adjustment.id,
    ),
    EntryReversed(:final reversal) =>
      book.entryOf(reversal.entryId) != null &&
          !book.reversals.any((r) => r.id == reversal.id),
    // O resto — fechamento, dívida, fatura — não desce do servidor.
    _ => false,
  };

  Iterable<LedgerEvent> _candidates(
    LedgerBook book,
    LedgerSnapshot snapshot,
  ) sync* {
    for (final event in snapshot.events) {
      final local = _asLocal(book, snapshot, event);
      if (local != null && accepts(book, local)) yield local;
    }
    // O que outro aparelho cancelou e este ainda mostra.
    for (final id in snapshot.cancelled) {
      final cancellation = EntryCancelled(
        id: 'cancellation-sync-$id',
        entryId: id,
        on: clock.today(),
        reason: 'cancelado em outro aparelho',
      );
      if (accepts(book, cancellation)) yield cancellation;
    }
  }

  /// O fato do servidor como fato **deste** aparelho: com a chave nascida do
  /// conteúdo, e trocado de tipo quando o livro daqui pede — o lançamento
  /// que já existe aqui não é registrado de novo, é corrigido.
  LedgerEvent? _asLocal(
    LedgerBook book,
    LedgerSnapshot snapshot,
    LedgerEvent event,
  ) => switch (event) {
    EntryRecorded(:final entry) => _entry(book, snapshot, entry),
    PlanDefined(:final setup) => PlanDefined(
      id: 'plan-sync-${setup.definedAt?.millisecondsSinceEpoch ?? 0}',
      setup: setup,
    ),
    CardDefined(:final card) => CardDefined(
      id: 'card-sync-${card.id}',
      card: card,
    ),
    IncomeReceived() || VoucherBalanceAdjusted() || EntryReversed() => event,
    _ => null,
  };

  /// O que o servidor já cancelou não volta por aqui de jeito nenhum.
  LedgerEvent? _entry(LedgerBook book, LedgerSnapshot snapshot, Entry entry) {
    if (snapshot.cancelled.contains(entry.id)) return null;
    if (book.entryOf(entry.id) == null) return EntryRecorded(entry);
    // A chave leva o carimbo da correção, e não só o conteúdo: um lançamento
    // corrigido de volta a uma versão já vista ganharia a mesma chave, o
    // registro a descartaria em silêncio, e ao reabrir o app a versão certa
    // teria sumido. Sem carimbo — servidor antigo — vale o conteúdo.
    final stamp =
        entry.revisedAt?.millisecondsSinceEpoch ?? _signatureOf(entry).hashCode;
    return EntryCorrected(
      id: 'correction-sync-${entry.id}-${stamp.toRadixString(16)}',
      entry: entry,
      on: clock.today(),
      reason: 'corrigido em outro aparelho',
    );
  }

  /// A mesma assinatura da subida: tudo o que no lançamento é conteúdo.
  static String _signatureOf(Entry entry) =>
      LedgerUplink.signatureOf(EntryCodec.fromEntry(entry));
}
