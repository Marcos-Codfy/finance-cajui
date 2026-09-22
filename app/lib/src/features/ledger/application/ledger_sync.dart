import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:domain/domain.dart';

/// Leva o livro do aparelho ao servidor, para o assistente ter com que
/// responder (RN-781, RN-915).
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
  /// Cria o sincronismo sobre [uplink].
  const new(this.uplink);

  /// Por onde o livro sobe.
  final LedgerUplink uplink;

  /// Manda o que falta. Devolve quantos lançamentos subiram e o primeiro
  /// erro, se houver — a primeira recusa interrompe: insistir com o servidor
  /// recusando só gasta bateria.
  Future<(int sent, ErrorCode? error)> run(LedgerBook book) async {
    if (!uplink.isPaired) return (0, ErrorCode.auth03);
    final cadastro = await _sendCategories(book) ?? await _sendCards(book);
    if (cadastro != null) return (0, cadastro);
    final (remote, failure) = await uplink.remoteEntries();
    if (failure != null) return (0, failure);
    final (sent, refused) = await _sendEntries(book, remote);
    // O plano e o que entrou vão por último e não interrompem nada: sem eles
    // o assistente ainda responde quanto saiu — só não responde quanto ainda
    // cabe nem quanto sobrou de vale.
    return (sent, refused ?? await _sendPlan(book) ?? await _sendIncome(book));
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
    Map<String, String> remote,
  ) async {
    var sent = 0;
    ErrorCode? refused;
    final live = {for (final entry in book.entries) entry.id: entry};
    for (final entry in book.entries) {
      final pending = remote[entry.id] != _signatureOf(entry);
      final error = await _sendOne(entry, remote[entry.id]);
      refused ??= error;
      if (error == null && pending) sent++;
    }
    // O que o servidor tem e o aparelho não tem mais foi cancelado aqui.
    for (final id in remote.keys.where((id) => !live.containsKey(id))) {
      final error = await uplink.cancelEntry(id);
      refused ??= error;
      if (error == null) sent++;
    }
    return (sent, refused);
  }

  Future<ErrorCode?> _sendOne(Entry entry, String? remote) async {
    final request = EntryCodec.fromEntry(entry);
    if (remote == null) return await uplink.sendEntry(request);
    if (remote == _signatureOf(entry)) return null;
    return await uplink.reviseEntry(request);
  }

  static String _signatureOf(Entry entry) => LedgerUplink.signature(
    cents: entry.amount.cents,
    occurredOn: '${entry.occurredOn}',
    categoryId: entry.categoryId,
    description: entry.description,
  );
}
