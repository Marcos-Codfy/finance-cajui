import 'package:persistence/persistence.dart';
import 'package:server/src/http/error_response.dart';
import 'package:server/src/ledger/ledger_state.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// O topo do registro: a pergunta mais barata que um aparelho pode fazer.
///
/// Responde dois números. `seq` é a âncora contra o corte do fim do
/// registro (T-39): o maior `seq` que existe. `ledgerSeq` é o do último
/// evento que **mexeu no livro** (ADR-024), e é o que os aparelhos olham a
/// cada 20 segundos para saber se há o que descer — o uso da IA também
/// grava evento, e contá-lo faria todo aparelho descer o livro inteiro a
/// cada pergunta feita ao assistente.
final class HeadRoutes {
  /// Cria a rota sobre o registro [store] e o estado [state].
  const new({required this.store, required this.state});

  /// O registro de eventos.
  final EventStore store;

  /// A projeção do livro.
  final LedgerState state;

  /// O roteador, montado em `/v1`.
  Router get router => Router()..get('/head', _head);

  Response _head(Request request) => Responses.json({
    'seq': store.events.length,
    'ledgerSeq': state.ledgerSeq,
  });
}
