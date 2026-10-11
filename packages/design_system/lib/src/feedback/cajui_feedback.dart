/// O que o design system pede ao mundo físico quando algo acontece: um som,
/// uma vibração, ou nada.
///
/// Os componentes só conhecem esta interface. Quem decide se há som, qual é,
/// e se o aparelho está no silencioso é a implementação — o que deixa o som
/// desligado por padrão sem nenhum componente precisar saber disso.
abstract interface class CajuiFeedback {
  /// Toque num controle.
  void tap();

  /// Uma chave mudou de posição.
  void toggle({required bool on});

  /// Uma folha ou um aviso abriu.
  void open();

  /// Algo foi salvo: lançamento, ajuste, regra aprendida.
  void saved();

  /// Um aviso que pede atenção. É uma nota grave e macia: não existe som de
  /// erro no Cajui.
  void notice();

  /// Uma conquista: dívida quitada, semanas seguidas dentro do limite.
  void achievement();

  /// Um lançamento acabou de entrar: a semente caindo.
  void entrySaved();

  /// Algo foi desfeito a pedido de quem usa: a folha.
  void undone();
}
