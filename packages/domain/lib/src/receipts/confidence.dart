/// O quanto o app confia no que propôs para um campo, em três zonas
/// (RN-744).
enum Confidence {
  /// O campo vem preenchido, e dá para editar.
  high,

  /// O app ficou entre dois ou três candidatos, e não escolhe por conta.
  medium,

  /// O campo vem vazio; se for a categoria, vira pergunta.
  low,
}
