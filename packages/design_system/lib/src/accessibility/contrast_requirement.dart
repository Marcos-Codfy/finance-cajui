/// O mínimo de contraste que a WCAG 2.2 AA exige, conforme o uso da cor.
enum ContrastRequirement {
  /// Texto normal: 4,5:1 (critério 1.4.3).
  text(4.5, 'texto'),

  /// Texto grande, ícone e contorno de componente: 3:1 (1.4.3 e 1.4.11).
  largeTextOrComponent(3, 'texto grande ou componente');

  new(this.minimum, this.label);

  /// A razão mínima aceita.
  final double minimum;

  /// O nome do uso, para a tabela.
  final String label;
}
