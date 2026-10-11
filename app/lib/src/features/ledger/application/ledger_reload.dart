import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_downlink.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reler o livro do servidor **no lugar**, sem passar por "carregando"
/// (ADR-024). Só vale para a consulta pela web.
///
/// O livro da web é o do servidor, e o jeito de atualizá-lo era
/// `ref.invalidate`: a tela de lançamentos voltava ao esqueleto de
/// carregamento por um instante, e uma rede caída no meio deixava o mês
/// zerado. Agora que a web relê sozinha a cada mudança feita no celular,
/// isso aconteceria várias vezes por dia. Aqui o livro novo entra de uma
/// vez, e sem resposta o que está na tela fica.
mixin LedgerReload on AsyncNotifier<LedgerBook> {
  /// Relê o livro do servidor e devolve se ele entrou. No celular não faz
  /// nada: lá o livro é o registro do aparelho, e o que vem do servidor
  /// entra pela descida, fato a fato.
  Future<bool> reload() async {
    if (ref.read(ledgerUplinkProvider).isPaired) return false;
    final snapshot = await ref.read(ledgerDownlinkProvider).snapshot();
    if (snapshot == null) return false;
    state = AsyncData(
      snapshot.events.fold(
        DefaultCatalog.emptyBook,
        (book, event) => book.apply(event),
      ),
    );
    return true;
  }
}
