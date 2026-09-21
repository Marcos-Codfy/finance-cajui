/// Uma recusa do domínio: a regra que não deixou a operação acontecer, com os
/// dados que o texto do erro vai usar.
///
/// A hierarquia é selada: um `switch` sobre `Failure` é exaustivo, e uma
/// falha nova sem tratamento — sem código no catálogo, sem texto na tela —
/// **não compila** (ADR-015). Cada caso corresponde a uma linha de
/// `docs/spec/error-catalog.md`.
///
/// Só moram aqui as falhas de regra de negócio. Falha de rede, de leitura de
/// comprovante ou de autenticação nasce nas camadas de fora, em hierarquias
/// próprias.
sealed class Failure {
  const new();
}
