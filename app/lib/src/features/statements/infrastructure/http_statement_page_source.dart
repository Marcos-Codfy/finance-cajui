import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';
import 'package:cajui/src/features/statements/application/statement_page_source.dart';

/// A leitura de uma página de extrato pelo servidor, em
/// `POST /v1/statements/read-part` (ADR-030), com a chave da casa.
///
/// Sem a chave, sem rede, IA fora do ar: a falha volta com o código do
/// catálogo, e quem lê as páginas decide tentar de novo ou seguir.
final class HttpStatementPageSource implements StatementPageSource {
  /// Cria a leitura sobre [_api].
  const new(this._api);

  final CajuiApi _api;

  /// Quanto se espera por uma página. A resposta cortada é lida de novo em
  /// metades (RN-1103): duas leituras de até 35 s no servidor, e a imagem
  /// subindo pela rede do celular.
  static const wait = Duration(seconds: 90);

  @override
  Future<StatementPageOutcome> read(
    StatementPageRequest request, {
    required bool Function(String id) knowsCategory,
  }) async {
    final outcome = await _api.authenticated(
      (token) => _api.post(
        '/v1/statements/read-part',
        request.toJson(),
        token: token,
        waitFor: wait,
      ),
    );
    final body = outcome.body;
    if (body == null) {
      return (reply: null, failure: outcome.failure?.code ?? ErrorCode.net01);
    }
    try {
      final reply = StatementPageReply.fromJson(
        body,
        knowsCategory: knowsCategory,
      );
      return (reply: reply, failure: null);
    } on Object {
      // Resposta fora do formato é o mesmo que resposta nenhuma: a página
      // é tentada de novo, e não derruba as outras.
      return (reply: null, failure: ErrorCode.ai04);
    }
  }
}
