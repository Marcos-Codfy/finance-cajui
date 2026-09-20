/// Durações de animação. Nada passa de 600 ms: movimento que atrasa a leitura
/// de um número deixa de ser requinte e vira obstáculo.
abstract final class CajuiDurations {
  /// 90 ms — resposta ao toque. Precisa caber abaixo de 100 ms (RNF-PERF).
  static const instant = Duration(milliseconds: 90);

  /// 180 ms — mudança de estado de um controle.
  static const fast = Duration(milliseconds: 180);

  /// 260 ms — entrada de item, abertura de aviso.
  static const base = Duration(milliseconds: 260);

  /// 420 ms — troca de tela, folha inferior.
  static const slow = Duration(milliseconds: 420);

  /// 600 ms — teto. Só para o ícone-herói de uma conquista.
  static const slowest = Duration(milliseconds: 600);

  /// 35 ms — diferença entre itens de uma lista que entra em cascata.
  static const stagger = Duration(milliseconds: 35);

  /// No nível `reduced`, toda transição vira uma fusão curta deste tamanho.
  static const reducedFade = Duration(milliseconds: 120);
}
