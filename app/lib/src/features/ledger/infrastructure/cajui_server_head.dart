import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';
import 'package:cajui/src/features/ledger/application/server_head.dart';

/// O topo do registro pela API do Cajui: `GET /v1/head` (ADR-024).
///
/// Servidor anterior ao `ledgerSeq` responde só o `seq`, e ele serve do
/// mesmo jeito — anda um pouco mais vezes, porque conta também o uso da
/// IA, mas nunca deixa de andar quando o livro muda.
final class CajuiServerHead implements ServerHead {
  /// Cria o topo sobre o cliente [_api].
  const new(this._api);

  final CajuiApi _api;

  @override
  Future<int?> ledgerSeq() async {
    final outcome = await _api.authenticated(
      (token) => _api.send('GET', '/v1/head', token: token),
    );
    final body = outcome.body;
    if (body == null) return null;
    final seq = body['ledgerSeq'] ?? body['seq'];
    return seq is int ? seq : null;
  }
}
