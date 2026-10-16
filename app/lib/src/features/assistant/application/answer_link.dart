/// Para onde a resposta da Juju aponta, quando ela fala de números que o
/// app mostra: um atalho logo abaixo leva lá, para conferir de onde saiu o
/// número (16/10/2026 — a Juju já tinha dito outra sobra que a da tela).
enum AnswerLink {
  /// O Meu mês: sobra, falta, o que entra e o que sai.
  month,

  /// As dívidas: quanto ainda se deve.
  debts;

  /// O atalho de [text], ou nenhum. Só resposta com valor em reais aponta:
  /// "Certo." não leva a lugar nenhum.
  static AnswerLink? of(String text) {
    final lower = text.toLowerCase();
    if (!lower.contains(r'r$')) return null;
    if (_debts.any(lower.contains)) return debts;
    if (_month.any(lower.contains)) return month;
    return null;
  }

  static const _debts = ['dívida', 'divida', 'devo', 'deve '];
  static const _month = ['sobra', 'falta', 'entra', 'sai do bolso', 'gast'];
}
