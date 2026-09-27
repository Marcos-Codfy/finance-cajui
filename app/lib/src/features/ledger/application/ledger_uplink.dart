import 'package:api_contract/api_contract.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O que o servidor já tem do que entrou: os identificadores dos
/// recebimentos e dos acertos de saldo do vale que ele conhece.
typedef RemoteIncome = ({Set<String> receipts, Set<String> adjustments});

/// O que o servidor tem de lançamentos: a assinatura dos vivos, por
/// identificador, o carimbo da última correção de cada um (só dos que já
/// foram corrigidos), e os que **já foram cancelados** em algum aparelho.
/// Sem a última parte, o celular que ainda tinha o lançamento o mandaria
/// de volta, desfazendo o cancelamento feito no outro; sem o carimbo, o
/// celular atrasado empurraria a versão velha por cima da nova (BL-062).
typedef RemoteEntries = ({
  Map<String, String> signatures,
  Map<String, DateTime> revisedAt,
  Set<String> cancelled,
});

/// O caminho de subida do livro: o que está no aparelho chegando ao servidor
/// (RN-781).
///
/// Existe porque o assistente monta o contexto **no servidor** (RN-915) —
/// ele não aceita número vindo do app, e faz bem. A consequência é que, sem
/// esta porta, o servidor não tem número nenhum para montar contexto com.
///
/// Subir é sempre seguro de repetir: cada operação tem chave própria, e o
/// servidor descarta a repetida.
abstract interface class LedgerUplink {
  /// Se este aparelho já tem com quem falar.
  bool get isPaired;

  /// Se há sessão aberta com o servidor **agora**.
  ///
  /// Quem pergunta é a subida silenciosa: abrir sessão pede a digital, e
  /// pedir a digital no meio de um lançamento é pior do que não subir na
  /// hora. Com a sessão de um dia, isso quer dizer que o primeiro envio do
  /// dia é a pedido e os seguintes acontecem sozinhos.
  bool get hasOpenSession;

  /// A assinatura de um lançamento: tudo o que nele é **conteúdo**, num
  /// texto comparável. É por ela que se sabe se o servidor tem a versão
  /// em vigor — e, entre dois aparelhos, se um deles corrigiu algo.
  ///
  /// Antes eram só os quatro campos que mudam número na resposta do
  /// assistente. Com dois celulares, trocar a forma de pagamento também
  /// precisa atravessar: é o que diz se saiu do vale ou do dinheiro
  /// (RN-111). Ficam de fora o carimbo — ele diz **quando**, não **o
  /// quê** — e o valor da parcela, que o servidor recalcula sem juros e
  /// faria toda compra com juros parecer corrigida para sempre (BL-054).
  static String signatureOf(CreateEntryRequest request) {
    final lines = [
      for (final line in request.paymentLines)
        '${line.paymentMethodId}:${line.kind}:${line.amountCents}',
    ].join('+');
    return [
      request.amountCents,
      request.occurredOn,
      request.categoryId,
      request.description,
      lines,
      request.installments ?? 1,
      request.isExceptional,
    ].join('|');
  }

  /// As categorias que o servidor já conhece.
  Future<(Set<String>, ErrorCode?)> remoteCategories();

  /// Os cartões que o servidor já conhece. Sem eles, compra parcelada é
  /// recusada: o plano de parcelas é recalculado a partir do cartão.
  Future<(Set<String>, ErrorCode?)> remoteCards();

  /// Cadastra o cartão no servidor.
  Future<ErrorCode?> sendCard(Map<String, Object?> card);

  /// O que o servidor já tem do que entrou.
  Future<(RemoteIncome, ErrorCode?)> remoteIncome();

  /// Manda um recebimento: salário, crédito do vale, entrada avulsa.
  Future<ErrorCode?> sendIncome(Map<String, Object?> receipt);

  /// Manda um acerto de saldo do vale (RN-123).
  Future<ErrorCode?> sendVoucherAdjustment(Map<String, Object?> adjustment);

  /// Manda o plano do mês inteiro: renda, fixos, faixas e parcelas.
  ///
  /// Vai inteiro, e não campo a campo, porque é assim que ele vive no
  /// aparelho — e meio plano no servidor daria resposta pior do que plano
  /// nenhum. Sem ele o assistente sabe quanto saiu, mas não quanto ainda
  /// cabe (BL-049).
  Future<ErrorCode?> sendPlan(Map<String, Object?> plan);

  /// Os lançamentos que o servidor tem, e os que ele já cancelou.
  Future<(RemoteEntries, ErrorCode?)> remoteEntries();

  /// Cadastra a categoria no servidor.
  Future<ErrorCode?> sendCategory(Map<String, Object?> category);

  /// Manda um lançamento novo.
  Future<ErrorCode?> sendEntry(CreateEntryRequest entry);

  /// Manda a versão que passou a valer de um lançamento já enviado.
  Future<ErrorCode?> reviseEntry(CreateEntryRequest entry);

  /// Os estornos que o servidor já tem.
  Future<(Set<String>, ErrorCode?)> remoteReversals();

  /// Manda um estorno: dinheiro de uma compra que voltou (RN-209).
  Future<ErrorCode?> sendReversal(Map<String, Object?> reversal);

  /// Avisa que um lançamento foi cancelado e não vale mais.
  Future<ErrorCode?> cancelEntry(String id);
}

/// Por onde o livro sobe. A raiz do app decide qual.
final ledgerUplinkProvider = Provider<LedgerUplink>(
  (ref) => throw StateError('ledgerUplinkProvider sem override na raiz.'),
);
