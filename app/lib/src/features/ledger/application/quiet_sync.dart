import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_downlink.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/ledger/application/ledger_pull.dart';
import 'package:cajui/src/features/ledger/application/ledger_sync.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A subida que acontece sozinha, depois de cada lançamento (RN-781).
///
/// Antes nada subia sem alguém pedir: quem lançava e nunca perguntava nada
/// ao assistente ficava com o servidor vazio — e a consulta pela web, que lê
/// o servidor, mostrava um mês que não existia, sem dizer por quê.
///
/// Duas regras a governam.
///
/// **Sobe sempre que dá.** Com a chave da casa (ADR-020) não há digital a
/// pedir: cada lançamento sobe na hora, e traz de volta o que o outro
/// celular fez. O que não sobe — sem rede — sobe na próxima.
///
/// **Nada disto chega à tela.** A subida é uma cópia: o livro deste aparelho
/// já está gravado, e falhar em copiá-lo não é erro de quem acabou de
/// lançar. O que não subiu sobe na próxima.
final class QuietSync {
  /// Cria a subida silenciosa sobre [_sync].
  new(this._sync);

  /// A subida e a descida das portas que a raiz do app ligou, gravando o
  /// que desce por [absorb] — o do controlador do livro, que confere de
  /// novo, já na fila, se o fato ainda faz diferença.
  factory over(
    Ref ref, {
    required Future<bool> Function(LedgerEvent event) absorb,
  }) => QuietSync(
    LedgerSync(
      ref.read(ledgerUplinkProvider),
      pull: LedgerPull(
        ref.read(ledgerDownlinkProvider),
        clock: ref.read(clockProvider),
        absorb: absorb,
      ),
    ),
  );

  final LedgerSync _sync;
  Future<void>? _running;
  LedgerBook? _queued;

  /// Pede que [book] suba, quando der.
  ///
  /// Uma subida por vez: lançar três coisas seguidas não abre três subidas.
  /// O que for pedido enquanto uma está no ar espera e sobe logo depois, já
  /// com o livro mais recente — nenhum lançamento fica para trás.
  void schedule(LedgerBook book) {
    if (_running != null) {
      _queued = book;
      return;
    }
    _running = _run(book).whenComplete(_afterRun);
  }

  /// Pede que [book] suba e desça, e espera acabar.
  ///
  /// É para quem precisa do servidor em dia antes de seguir — a pergunta
  /// ao assistente, a conferência ao vivo (ADR-024). Passa pela mesma fila
  /// de [schedule]: continua havendo **uma** sincronização por vez, e duas
  /// ao mesmo tempo mandariam o mesmo lançamento duas vezes.
  Future<void> request(LedgerBook book) {
    schedule(book);
    return settled;
  }

  /// Espera o que estiver no ar acabar, inclusive o que ficou na fila.
  Future<void> get settled async {
    while (_running != null) {
      await _running;
    }
  }

  Future<void> _run(LedgerBook book) async {
    try {
      if (!await _sync.uplink.canSendQuietly()) return;
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
