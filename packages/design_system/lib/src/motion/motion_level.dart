/// Quanto de movimento o app usa.
///
/// O nível cai por medição de quadros no próprio aparelho, nunca por modelo de
/// celular, e cai também quando o sistema pede movimento reduzido. O efeito
/// degrada; o app não trava (RNF-PERF-02, RNF-A11Y-07).
enum MotionLevel {
  /// Tudo: molas, paralaxe, cascata, contagem de número, herói animado.
  full,

  /// Sem sombreador, sem desfoque e com paralaxe simplificada. As molas ficam.
  lite,

  /// Transições viram fusão curta. Sem paralaxe, cascata, contagem nem herói
  /// animado: o herói mostra o quadro final, parado.
  reduced;

  /// Se animações decorativas — as que não explicam nada — podem rodar.
  bool get allowsDecorativeMotion => this == MotionLevel.full;

  /// Se a resposta em mola ao toque pode rodar.
  bool get allowsSpring => this != MotionLevel.reduced;
}
