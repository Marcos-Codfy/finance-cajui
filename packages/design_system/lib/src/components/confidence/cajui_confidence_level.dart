/// A zona de confiança de um campo proposto pela classificação (RN-742).
///
/// É um conceito de tela: diz como o campo aparece, não como a confiança foi
/// calculada — isso é do domínio. O texto segue o guia de voz: primeira
/// pessoa, sem jargão.
enum CajuiConfidenceLevel {
  /// Campo preenchido num chip editável.
  high(filledDots: 3, label: 'Confiança alta'),

  /// Dois ou três candidatos, nenhum pré-selecionado.
  medium(filledDots: 2, label: 'Fiquei entre estas'),

  /// Campo vazio com seletor, sem palpite.
  low(filledDots: 1, label: 'Não consegui identificar');

  new({required this.filledDots, required this.label});

  /// Quantos dos três pontos ficam cheios.
  final int filledDots;

  /// O que aparece escrito ao lado dos pontos.
  final String label;
}
