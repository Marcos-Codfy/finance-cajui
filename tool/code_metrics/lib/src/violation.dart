/// Um limite estourado, com o lugar exato e a medida.
class Violation {
  /// Cria a violação da regra [rule] em [path], na linha [line].
  const new({
    required this.path,
    required this.line,
    required this.rule,
    required this.message,
  });

  /// O arquivo, relativo à raiz conferida.
  final String path;

  /// A linha em que o problema começa.
  final int line;

  /// O nome curto da regra: `file-lines`, `function-lines`, `nesting`,
  /// `public-types` ou `parse`.
  final String rule;

  /// A medida e o limite, em texto.
  final String message;

  /// No formato `arquivo:linha`, que o terminal e o editor sabem abrir.
  @override
  String toString() => '$path:$line  [$rule] $message';
}
