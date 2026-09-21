/// O disjuntor da IA: depois de falhas seguidas, para de chamar por um tempo.
///
/// Insistir num serviço que está fora do ar só faz cada captura esperar o
/// prazo inteiro antes de cair nas regras locais. Com o disjuntor aberto, a
/// queda é imediata — e a pessoa nem percebe a espera.
final class CircuitBreaker {
  /// Cria o disjuntor. [now] existe para o teste controlar o relógio.
  new({
    this.failureThreshold = 3,
    this.cooldown = const Duration(minutes: 2),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Quantas falhas seguidas abrem o disjuntor.
  final int failureThreshold;

  /// Por quanto tempo ele fica aberto.
  final Duration cooldown;

  final DateTime Function() _now;
  int _failures = 0;
  DateTime? _openedAt;

  /// Dá para chamar o serviço agora.
  bool get allowsCall {
    final opened = _openedAt;
    if (opened == null) return true;
    if (_now().difference(opened) < cooldown) return false;
    _openedAt = null;
    _failures = 0;
    return true;
  }

  /// A chamada deu certo: zera a contagem.
  void recordSuccess() => _failures = 0;

  /// A chamada falhou: conta, e abre o disjuntor no limite.
  void recordFailure() {
    _failures++;
    if (_failures >= failureThreshold) _openedAt = _now();
  }
}
