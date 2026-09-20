/// As quatro formas que a tela de captura toma.
enum CaptureKind {
  /// Trabalhando: mensagem no centro e, no máximo, uma saída.
  progress,

  /// A confirmação: os campos preenchidos, para conferir e lançar.
  form,

  /// A pergunta de esclarecimento, com os candidatos.
  question,

  /// Um aviso que ocupa a tela: algo impediu a leitura.
  notice,
}
