import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_sync.dart';

/// A subida que acontece sozinha, depois de cada lançamento (RN-781).
///
/// Antes nada subia sem alguém pedir: quem lançava e nunca perguntava nada
/// ao assistente ficava com o servidor vazio — e a consulta pela web, que lê
/// o servidor, mostrava um mês que não existia, sem dizer por quê.
///
/// Duas regras a governam.
///
/// **Só sobe com sessão já aberta.** Abrir sessão pede a digital, e pedir a
/// digital no meio de um lançamento é pior do que não subir na hora: quem
/// está lançando está com pressa. Como a sessão dura um dia, na prática o
/// primeiro envio do dia é a pedido — pelo assistente ou por Ajustes — e
/// todos os seguintes acontecem sozinhos.
///
/// **Nada disto chega à tela.** A subida é uma cópia: o livro deste aparelho
/// já está gravado, e falhar em copiá-lo não é erro de quem acabou de
/// lançar. O que não subiu sobe na próxima.
final class QuietSync {
  /// Cria a subida silenciosa sobre [_sync].
  new(this._sync);

  final LedgerSync _sync;
  Future<void>? _running;
  LedgerBook? _queued;

  /// Pede que [book] suba, quando der.
  ///
  /// Uma subida por vez: lançar três coisas seguidas não abre três subidas.
  /// O que for pedido enquanto uma está no ar espera e sobe logo depois, já
  /// com o livro mais recente — nenhum lançamento fica para trás.
  void schedule(LedgerBook book) {
    if (!_sync.uplink.hasOpenSession) return;
    if (_running != null) {
      _queued = book;
      return;
    }
    _running = _run(book).whenComplete(_afterRun);
  }

  /// Espera o que estiver no ar acabar, inclusive o que ficou na fila. É
  /// para o teste: nenhuma tela espera por isto.
  Future<void> get settled async {
    while (_running != null) {
      await _running;
    }
  }

  Future<void> _run(LedgerBook book) async {
    try {
      await _sync.run(book);
    } on Object {
      // Sem rede, sem servidor, sessão vencida no meio: nada disso é assunto
      // de quem acabou de lançar.
    }
  }

  void _afterRun() {
    _running = null;
    final next = _queued;
    _queued = null;
    if (next != null) schedule(next);
  }
}
