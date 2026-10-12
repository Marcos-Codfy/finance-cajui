/// Por que uma linha de extrato virou pergunta (RN-1114).
enum LineDoubt {
  /// Não se sabe o que a movimentação é: gasto, alguém da casa, conta
  /// sua. Só a IA disse, ou é um Pix para alguém que ninguém ensinou.
  kind,

  /// É gasto, mas a categoria não está certa: ninguém ensinou, não é marca
  /// conhecida, e a IA não teve confiança alta.
  category,
}
