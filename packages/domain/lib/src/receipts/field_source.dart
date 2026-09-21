/// De onde veio o valor proposto para um campo (RN-741).
///
/// A ordem é a da precedência: o que a pessoa já ensinou vale mais que as
/// regras fixas, que valem mais que a IA (RN-750).
enum FieldSource {
  /// Uma correção anterior da própria pessoa: "Posto Avenida é combustível".
  learnedRule,

  /// As regras fixas do leitor local: o número ao lado de "TOTAL".
  fixedRule,

  /// A IA.
  ai,

  /// Ninguém conseguiu ler o campo.
  none,
}
