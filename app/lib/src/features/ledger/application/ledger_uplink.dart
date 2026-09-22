import 'package:api_contract/api_contract.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  /// A assinatura de um lançamento, para saber se o servidor tem a versão
  /// em vigor.
  ///
  /// São os quatro campos que **mudam número na resposta do assistente**.
  /// Correção que só troca a forma de pagamento não muda nenhuma conta do
  /// contexto, e por isso não obriga uma subida.
  static String signature({
    required int cents,
    required String occurredOn,
    required String categoryId,
    required String description,
  }) => '$cents|$occurredOn|$categoryId|$description';

  /// As categorias que o servidor já conhece.
  Future<(Set<String>, ErrorCode?)> remoteCategories();

  /// Os cartões que o servidor já conhece. Sem eles, compra parcelada é
  /// recusada: o plano de parcelas é recalculado a partir do cartão.
  Future<(Set<String>, ErrorCode?)> remoteCards();

  /// Cadastra o cartão no servidor.
  Future<ErrorCode?> sendCard(Map<String, Object?> card);

  /// Manda o plano do mês inteiro: renda, fixos, faixas e parcelas.
  ///
  /// Vai inteiro, e não campo a campo, porque é assim que ele vive no
  /// aparelho — e meio plano no servidor daria resposta pior do que plano
  /// nenhum. Sem ele o assistente sabe quanto saiu, mas não quanto ainda
  /// cabe (BL-049).
  Future<ErrorCode?> sendPlan(Map<String, Object?> plan);

  /// As assinaturas dos lançamentos que o servidor tem, por identificador.
  Future<(Map<String, String>, ErrorCode?)> remoteEntries();

  /// Cadastra a categoria no servidor.
  Future<ErrorCode?> sendCategory(Map<String, Object?> category);

  /// Manda um lançamento novo.
  Future<ErrorCode?> sendEntry(CreateEntryRequest entry);

  /// Manda a versão que passou a valer de um lançamento já enviado.
  Future<ErrorCode?> reviseEntry(CreateEntryRequest entry);

  /// Avisa que um lançamento foi cancelado e não vale mais.
  Future<ErrorCode?> cancelEntry(String id);
}

/// Por onde o livro sobe. A raiz do app decide qual.
final ledgerUplinkProvider = Provider<LedgerUplink>(
  (ref) => throw StateError('ledgerUplinkProvider sem override na raiz.'),
);
