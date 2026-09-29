import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/ledger/application/device_facts.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_pull.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:domain/domain.dart';

/// O resultado de uma sincronização: o que subiu, o que desceu e a primeira
/// recusa, se houve.
typedef SyncOutcome = ({int sent, int received, ErrorCode? error});

/// Leva o livro do aparelho ao servidor, para o assistente ter com que
/// responder (RN-781, RN-915) — e traz de volta o que outro aparelho fez.
///
/// Não guarda marcador de "já enviei": **o servidor é o marcador**. A cada
/// subida se pergunta o que ele tem, e manda-se a diferença. Assim um
/// servidor restaurado de backup se completa sozinho, e um aparelho
/// reinstalado não duplica nada.
///
/// A subida acontece nos momentos em que a pessoa já está esperando o
/// servidor — antes de uma pergunta que precisa da IA, ou quando ela pede em
/// Ajustes. Sincronizar a cada lançamento pediria a digital a cada
/// lançamento, e isso ninguém merece.
final class LedgerSync {
  /// Cria o sincronismo sobre [uplink]. Com [pull], depois de subir ele
  /// também **desce** o que os outros aparelhos fizeram (BL-062).
  const new(this.uplink, {this.pull});

  /// Por onde o livro sobe.
  final LedgerUplink uplink;

  /// Por onde o livro desce; `null` onde não há o que descer.
  final LedgerPull? pull;

  /// Manda o que falta e traz o que falta. Devolve quantos lançamentos
  /// subiram, quantos fatos desceram e o primeiro erro, se houver.
  ///
  /// A ordem é **subir, depois descer**, e ela importa: subindo primeiro,
  /// tudo o que este aparelho tem já está no servidor quando a descida
  /// compara — e o que o servidor cancelou é cancelado aqui em vez de voltar.
  Future<SyncOutcome> run(LedgerBook book) async {
    if (!uplink.isPaired) {
      return (sent: 0, received: 0, error: ErrorCode.auth03);
    }
    final cadastro = await _sendCategories(book) ?? await _sendCards(book);
    if (cadastro != null) return (sent: 0, received: 0, error: cadastro);
    final (remote, failure) = await uplink.remoteEntries();
    if (failure != null) return (sent: 0, received: 0, error: failure);
    final (sent, refused) = await _sendEntries(book, remote);
    // O plano e o que entrou vão por último e não interrompem nada: sem eles
    // o assistente ainda responde quanto saiu — só não responde quanto ainda
    // cabe nem quanto sobrou de vale.
    final error =
        refused ??
        await _sendReversals(book) ??
        await _sendFacts(book) ??
        await _sendPlan(book) ??
        await _sendIncome(book);
    // A descida acontece mesmo com recusa na subida: o que o outro aparelho
    // fez não depende do que este não conseguiu mandar.
    final (received, broken) = await _pull(book);
    return (sent: sent, received: received, error: error ?? broken);
  }

  /// A descida não pode derrubar quem a chamou: resposta que o app não lê,
  /// disco que falhou no meio — vira o código da rede de segurança, e a
  /// tela volta a responder em vez de ficar presa em "enviando".
  Future<(int, ErrorCode?)> _pull(LedgerBook book) async {
    try {
      return (await pull?.run(book) ?? 0, null);
    } on Object {
      return (0, ErrorCode.app01);
    }
  }

  /// Os estornos (RN-209). Vão **depois** dos lançamentos, e não antes: o
  /// servidor recusa estorno de lançamento que ele ainda não conhece — e
  /// faz bem, porque é do lançamento que sai o que resta a estornar.
  Future<ErrorCode?> _sendReversals(LedgerBook book) async {
    if (book.reversals.isEmpty) return null;
    final (known, failure) = await uplink.remoteReversals();
    if (failure != null) return failure;
    for (final reversal in book.reversals) {
      if (known.contains(reversal.id)) continue;
      final error = await uplink.sendReversal(ReversalCodec.encode(reversal));
      if (error != null) return error;
    }
    return null;
  }

  /// Os fatos que o servidor guarda como estão (ADR-019). Vão depois dos
  /// lançamentos: a parcela de dívida paga aponta para um deles.
  Future<ErrorCode?> _sendFacts(LedgerBook book) async {
    if (book.facts.isEmpty) return null;
    final (known, failure) = await uplink.remoteFacts();
    if (failure != null) return failure;
    for (final event in book.facts) {
      final fact = DeviceFacts.of(event);
      if (fact == null || known.contains(fact.id)) continue;
      final error = await uplink.sendFact(fact);
      if (error != null) return error;
    }
    return null;
  }

  /// O que entrou: recebimentos e acertos de saldo do vale (RN-132, RN-123).
  ///
  /// Vão como **fatos**, e não como um saldo pronto: o servidor recalcula o
  /// saldo a partir deles e dos lançamentos, porque número vindo do cliente
  /// não se usa para responder (T-05, RN-915).
  Future<ErrorCode?> _sendIncome(LedgerBook book) async {
    final (remote, failure) = await uplink.remoteIncome();
    if (failure != null) return failure;
    for (final receipt in book.receipts) {
      if (remote.receipts.contains(receipt.id)) continue;
      final error = await uplink.sendIncome(IncomeCodec.encode(receipt));
      if (error != null) return error;
    }
    return await _sendAdjustments(book, remote.adjustments);
  }

  Future<ErrorCode?> _sendAdjustments(
    LedgerBook book,
    Set<String> known,
  ) async {
    for (final acerto in book.voucherAdjustments) {
      if (known.contains(acerto.id)) continue;
      final error = await uplink.sendVoucherAdjustment(
        IncomeCodec.encodeAdjustment(
          id: acerto.id,
          adjustment: acerto.amount,
          on: acerto.on,
          reason: acerto.reason,
        ),
      );
      if (error != null) return error;
    }
    return null;
  }

  /// Quem ainda não planejou não tem o que mandar, e um plano vazio subindo
  /// apagaria no servidor o plano que já estava lá.
  Future<ErrorCode?> _sendPlan(LedgerBook book) async => book.setup.isEmpty
      ? null
      : await uplink.sendPlan(MonthSetupCodec.encode(book.setup));

  /// O servidor recusa lançamento de categoria que ele não conhece, então as
  /// categorias vão primeiro.
  Future<ErrorCode?> _sendCategories(LedgerBook book) async {
    final (known, failure) = await uplink.remoteCategories();
    if (failure != null) return failure;
    for (final category in book.categories) {
      if (known.contains(category.id)) continue;
      final error = await uplink.sendCategory({
        'id': category.id,
        'name': category.name,
        'block': category.block.name,
        'groupId': category.groupId,
        'voucherEligible': category.voucherEligible,
      });
      if (error != null) return error;
    }
    return null;
  }

  /// Manda o que falta, **sem parar no primeiro tropeço**.
  ///
  /// Um lançamento que o servidor recusa não pode calar todos os que vêm
  /// depois dele: a lista está em ordem de inserção, então abortar ali
  /// deixaria o servidor com um mês pela metade — e o assistente
  /// respondendo com número incompleto sem ninguém saber por quê. Guarda-se
  /// a primeira recusa e segue-se em frente.
  /// Os cartões vão antes dos lançamentos, e pelo mesmo motivo que as
  /// categorias: sem o cartão, o servidor recusa toda compra parcelada —
  /// ele recalcula o plano de parcelas a partir dele.
  Future<ErrorCode?> _sendCards(LedgerBook book) async {
    if (book.cards.isEmpty) return null;
    final (known, failure) = await uplink.remoteCards();
    if (failure != null) return failure;
    for (final card in book.cards) {
      if (known.contains(card.id)) continue;
      final error = await uplink.sendCard(CardCodec.encodeCard(card));
      if (error != null) return error;
    }
    return null;
  }

  Future<(int, ErrorCode?)> _sendEntries(
    LedgerBook book,
    RemoteEntries remote,
  ) async {
    var sent = 0;
    ErrorCode? refused;
    final live = {for (final entry in book.entries) entry.id: entry};
    for (final entry in book.entries) {
      if (!_hasToGo(entry, remote)) continue;
      final error = await _sendOne(
        entry,
        isKnown: remote.signatures.containsKey(entry.id),
      );
      refused ??= error;
      if (error == null) sent++;
    }
    // Só o que foi cancelado **aqui** é cancelado lá. "O servidor tem e eu
    // não" também descreve o que ainda não desceu do outro aparelho — e
    // cancelar isso apagaria o que ele acabou de lançar (BL-062).
    final gone = remote.signatures.keys.where(
      (id) => !live.containsKey(id) && book.cancelledIds.contains(id),
    );
    for (final id in gone) {
      final error = await uplink.cancelEntry(id);
      refused ??= error;
      if (error == null) sent++;
    }
    return (sent, refused);
  }

  /// Se [entry] tem o que subir.
  ///
  /// Cancelado em outro aparelho não volta a subir daqui: quem o cancela
  /// por aqui é a descida, na sequência. E, quando o servidor tem uma versão
  /// **mais nova** pelo carimbo, a daqui não sobe por cima — a descida traz
  /// a nova para cá (BL-062).
  bool _hasToGo(Entry entry, RemoteEntries remote) {
    if (remote.cancelled.contains(entry.id)) return false;
    if (remote.signatures[entry.id] == _signatureOf(entry)) return false;
    return !EditStamp.isNewer(remote.revisedAt[entry.id], entry.revisedAt);
  }

  Future<ErrorCode?> _sendOne(Entry entry, {required bool isKnown}) async {
    final request = EntryCodec.fromEntry(entry);
    return isKnown
        ? await uplink.reviseEntry(request)
        : await uplink.sendEntry(request);
  }

  static String _signatureOf(Entry entry) =>
      LedgerUplink.signatureOf(EntryCodec.fromEntry(entry));
}
