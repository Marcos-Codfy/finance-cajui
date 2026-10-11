import 'dart:async';

import 'package:cajui/src/features/ledger/application/server_head.dart';

/// O relógio da conferência: a cada `every`, chama `tick`. É uma função
/// para o teste trocar o relógio de verdade por um que ele adianta à mão.
typedef Ticker = Timer Function(Duration every, void Function() tick);

/// A conferência ao vivo: cada aparelho vê o que o outro fez em até 20
/// segundos, sem gastar quase nada quando nada muda (ADR-024).
///
/// Antes o celular só descia o livro ao abrir, ao voltar ao app e em volta
/// de uma pergunta ao assistente, e a web lia o servidor uma vez: o que um
/// lançava, o outro só via quando fechava e abria de novo. Agora, enquanto
/// o app está na frente, pergunta-se ao servidor só o topo do registro — um
/// número — a cada [interval]. **Só quando ele anda** o livro desce, pelo
/// caminho de sempre.
///
/// Em segundo plano o relógio para: celular no bolso não gasta bateria nem
/// dados com isto. Uma conferência de cada vez: se a anterior ainda está no
/// ar, a nova é pulada — a seguinte pega o que ela pegaria.
final class LiveSync {
  /// Cria a conferência sobre o topo `head`. `refresh` desce o livro e diz
  /// se conseguiu; [ticker] troca o relógio no teste.
  new({required this._head, required this._refresh, Ticker? ticker})
    : _ticker = ticker ?? _periodic;

  /// De quanto em quanto tempo se pergunta ao servidor.
  static const interval = Duration(seconds: 20);

  final ServerHead _head;
  final Future<bool> Function() _refresh;
  final Ticker _ticker;
  Timer? _timer;
  int? _seen;
  Future<void>? _running;

  /// Se o relógio está andando: o app está na frente.
  bool get isRunning => _timer != null;

  static Timer _periodic(Duration every, void Function() tick) =>
      Timer.periodic(every, (_) => tick());

  /// O app veio para a frente: confere agora e passa a conferir a cada
  /// [interval]. Com [force], desce o livro mesmo sem o topo ter andado —
  /// no celular, voltar ao app também sobe o que ficou para trás sem rede.
  void resume({bool force = false}) {
    _timer?.cancel();
    _timer = _ticker(interval, () => unawaited(check()));
    unawaited(check(force: force));
  }

  /// O app foi para o fundo: para de perguntar.
  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  /// Uma conferência: pergunta o topo e desce o livro se ele andou desde a
  /// última vez — ou sempre, com [force]. A forçada espera a que estiver
  /// no ar; a comum, não: a próxima batida do relógio pega o que ela
  /// pegaria.
  Future<void> check({bool force = false}) async {
    for (var running = _running; running != null; running = _running) {
      if (!force) return;
      await running;
    }
    final run = _check(force: force);
    _running = run;
    try {
      await run;
    } finally {
      if (identical(_running, run)) _running = null;
    }
  }

  /// O topo é lido **antes** de descer: o que mudar enquanto o livro desce
  /// faz o topo andar de novo, e a próxima conferência pega. Lido depois,
  /// essa mudança seria dada como vista sem ter descido.
  Future<void> _check({required bool force}) async {
    final seq = await _quietly(_head.ledgerSeq);
    final previous = _seen;
    if (seq != null) _seen = seq;
    if (!force && (seq == null || seq == previous)) return;
    final done = await _quietly(_refresh) ?? false;
    // Não desceu: o topo volta ao que era, e a próxima conferência tenta.
    if (!done) _seen = previous;
  }

  /// Sem rede, sem servidor, livro que não abriu: nada disto chega à tela.
  /// A conferência seguinte tenta de novo.
  static Future<T?> _quietly<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object {
      return null;
    }
  }
}
