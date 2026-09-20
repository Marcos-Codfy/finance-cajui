/// Uma janela deslizante de tempos de quadro, que diz se o aparelho está
/// dando conta das animações.
///
/// É só aritmética, sem depender do Flutter: quem liga isto aos quadros de
/// verdade é o `FrameBudgetMonitor`. Separado assim, o critério de
/// rebaixamento é testável com números fixos.
class FrameBudgetWindow {
  /// Cria a janela. Os padrões são os do RNF-PERF-02: 120 quadros, e mais de
  /// 5% deles acima de 16,6 ms derruba o nível.
  new({
    this.size = 120,
    this.budget = const Duration(microseconds: 16600),
    this.tolerance = 0.05,
  });

  /// Quantos quadros a janela guarda.
  final int size;

  /// O orçamento de um quadro a 60 por segundo.
  final Duration budget;

  /// A fração de quadros estourados que a janela tolera.
  final double tolerance;

  final List<bool> _overBudget = [];

  /// Registra o tempo total de um quadro.
  void record(Duration frame) {
    _overBudget.add(frame > budget);
    if (_overBudget.length > size) _overBudget.removeAt(0);
  }

  /// Se a janela está cheia e passou da tolerância. Janela incompleta nunca
  /// acusa: os primeiros quadros de uma tela são sempre os piores.
  bool get isDropping {
    if (_overBudget.length < size) return false;
    final over = _overBudget.where((late) => late).length;
    return over / size > tolerance;
  }
}
