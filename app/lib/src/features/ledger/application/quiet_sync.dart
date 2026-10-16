import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_downlink.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/ledger/application/ledger_pull.dart';
import 'package:cajui/src/features/ledger/application/ledger_sync.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:cajui/src/features/ledger/application/sync_status_controller.dart';
import 'package:domain/domain.dart';
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
  new(this._sync, {this._status, this._clock});

  /// A subida e a descida das portas que a raiz do app ligou, gravando o
  /// que desce por [absorb] — o do controlador do livro, que confere de
  /// novo, já na fila, se o fato ainda faz diferença.
  factory over(
    Ref ref, {
    required Future<bool> Function(LedgerEvent event) absorb,
  }) => QuietSync(
    status: ref.read(syncStatusProvider.notifier),
    clock: ref.read(clockProvider),
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
  final SyncStatusController? _status;
  final Clock? _clock;
  Future<void>? _running;
  LedgerBook? _queued;
  SyncOutcome? _last;

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
  ///
  /// Diz se a última volta desceu o que o servidor tinha: sem rede, ou com
  /// a descida quebrada, `false` — e quem pediu tenta de novo depois.
  Future<bool> request(LedgerBook book) async {
    schedule(book);
    await settled;
    return _last?.pulled ?? false;
  }

  /// Espera o que estiver no ar acabar, inclusive o que ficou na fila.
  Future<void> get settled async {
    while (_running != null) {
      await _running;
    }
  }

  Future<void> _run(LedgerBook book) async {
    var started = false;
    try {
      _last = null;
      if (!await _sync.uplink.canSendQuietly()) return;
      _status?.started();
      started = true;
      _last = await _sync.run(book);
    } on Object {
      // Sem rede, sem servidor, sessão vencida no meio: nada disso é assunto
      // de quem acabou de lançar — só o selo do Início muda de tom.
    }
    final (clock, last) = (_clock, _last);
    if (!started || clock == null) return;
    _status?.finished(ok: last != null && last.error == null, at: clock.now());
  }

  void _afterRun() {
    _running = null;
    final next = _queued;
    _queued = null;
    if (next != null) schedule(next);
  }
}
