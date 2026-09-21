/// O que o guia de voz do Cajui proíbe, em forma de dado (RN-944).
///
/// A lista é **uma só**: confere os textos de erro do app, o retorno
/// periódico e a resposta da IA. Mora no domínio para os dois lados — app e
/// servidor — reprovarem exatamente os mesmos termos.
abstract final class VoiceGuide {
  /// Termos que julgam, assustam ou não dizem nada. Em minúsculas.
  static const forbiddenTerms = [
    // Julgamento e alarme (D-UX-22).
    'déficit',
    'rombo',
    'no vermelho',
    'estourou',
    'você deveria',
    'cuidado!',
    'infelizmente',
    'supérfluo',
    'gastou demais',
    // Erro que não diz o quê (catálogo de erros, regra 1).
    'algo deu errado',
    'erro inesperado',
    'ops!',
    'tente novamente mais tarde',
  ];

  /// Os termos proibidos que aparecem em [text], sem diferenciar maiúsculas.
  static List<String> violations(String text) {
    final lowered = text.toLowerCase();
    return [
      for (final term in forbiddenTerms)
        if (lowered.contains(term)) term,
    ];
  }
}
