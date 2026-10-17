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

  /// 45 ms — o passo entre uma palavra e a seguinte numa resposta que vai
  /// aparecendo. Umas 22 palavras por segundo: mais rápido que a leitura,
  /// para ninguém esperar o texto, e devagar o bastante para se ver chegar.
  static const wordStep = Duration(milliseconds: 45);

  /// 4 s — o máximo que uma resposta leva para aparecer inteira, qualquer
  /// que seja o tamanho. Abaixo dos 5 s em que a WCAG 2.2.2 pede um jeito de
  /// pausar o que se move sozinho — e, mesmo assim, um toque já mostra tudo.
  static const streamCap = Duration(seconds: 4);

  /// A janela do Desfazer depois de cancelar deslizando: dá tempo de ler e
  /// tocar, e não deixa o cancelamento pendurado.
  static const undo = Duration(seconds: 5);

  /// 6 s — um balanço inteiro das ilustrações do Cerrado ao vento: lento o
  /// bastante para ser ambiente, e não chamar o olho como um aviso.
  static const breeze = Duration(seconds: 6);
}
