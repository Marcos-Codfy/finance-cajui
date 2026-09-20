/// Os limites de tamanho que o projeto se impõe.
///
/// Não são estética: arquivo curto e função curta são o que mantém cada peça
/// legível de uma vez só, e o que obriga a dar nome às partes.
class Limits {
  /// Cria um conjunto de limites. Os padrões são os do projeto.
  const new({
    this.maxFileLines = 300,
    this.maxFunctionLines = 30,
    this.maxNesting = 3,
    this.maxPublicTypes = 1,
  });

  /// Linhas por arquivo, contando tudo.
  final int maxFileLines;

  /// Linhas por função, da assinatura à chave que fecha.
  final int maxFunctionLines;

  /// Níveis de bloco de controle dentro de uma função.
  final int maxNesting;

  /// Classes, enums, mixins e tipos de extensão públicos por arquivo.
  final int maxPublicTypes;
}
