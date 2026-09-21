/// Conta requisições por origem e no total, numa janela de tempo fixa
/// (RNF-SEC-08).
///
/// Dois limites, porque servem a coisas diferentes: o **por origem** segura
/// um cliente insistente; o **global** segura a varredura distribuída, em que
/// cada origem manda pouco. Vive em memória: há um processo só, e perder a
/// contagem num reinício é inofensivo.
final class RateLimiter {
  /// Cria o limitador. [now] existe para o teste controlar o relógio.
  new({
    required this.perOrigin,
    required this.global,
    this.window = const Duration(minutes: 1),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Quantas requisições uma origem pode fazer por janela.
  final int perOrigin;

  /// Quantas requisições o servidor aceita por janela, de todas as origens.
  final int global;

  /// O tamanho da janela.
  final Duration window;

  final DateTime Function() _now;
  final Map<String, int> _counts = {};
  DateTime _windowStart = DateTime.fromMillisecondsSinceEpoch(0);
  int _total = 0;

  /// Registra uma requisição de [origin]. Devolve nulo se ela cabe no limite;
  /// senão, **em quantos segundos** a janela vira — o que vai no
  /// `Retry-After` e no texto de `E-RATE-01`.
  int? retryAfterSeconds(String origin) {
    final now = _now();
    if (now.difference(_windowStart) >= window) {
      _windowStart = now;
      _counts.clear();
      _total = 0;
    }
    final count = (_counts[origin] ?? 0) + 1;
    if (count > perOrigin || _total + 1 > global) {
      final left = window - now.difference(_windowStart);
      return left.inSeconds < 1 ? 1 : left.inSeconds;
    }
    _counts[origin] = count;
    _total++;
    return null;
  }
}
