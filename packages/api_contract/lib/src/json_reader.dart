/// Lê um objeto JSON campo a campo, recusando o que não for exatamente o
/// esperado.
///
/// Toda entrada é tratada como não confiável (RNF-SEC-09): campo com tipo
/// errado, campo faltando e **campo a mais** lançam [FormatException], que a
/// API devolve como `E-REQ-01`. Recusar campo desconhecido é o que impede um
/// pedido de escrever em atributo que ninguém pretendia expor.
final class JsonReader {
  /// Cria o leitor sobre [json], que só pode conter os campos [allowed].
  new(Object? json, {required Set<String> allowed})
    : _json = json is Map<String, Object?>
          ? json
          : throw const FormatException('esperava um objeto') {
    final unknown = _json.keys.where((key) => !allowed.contains(key));
    if (unknown.isNotEmpty) {
      throw FormatException('campo não esperado: ${unknown.first}');
    }
  }

  final Map<String, Object?> _json;

  T _read<T>(String field) {
    final value = _json[field];
    if (value is T) return value;
    throw FormatException('campo "$field" ausente ou de tipo errado');
  }

  /// Um texto obrigatório, não vazio e com no máximo [maxLength] caracteres.
  String string(String field, {int maxLength = 200}) {
    final value = _read<String>(field).trim();
    if (value.isEmpty || value.length > maxLength) {
      throw FormatException('campo "$field" vazio ou longo demais');
    }
    return value;
  }

  /// Um inteiro obrigatório.
  int integer(String field) => _read<int>(field);

  /// Um booleano opcional; ausente vale [orElse].
  bool boolean(String field, {required bool orElse}) =>
      _json.containsKey(field) ? _read<bool>(field) : orElse;

  /// Uma lista obrigatória, com entre 1 e [maxItems] itens.
  List<Object?> list(String field, {int maxItems = 20}) {
    final value = _read<List<Object?>>(field);
    if (value.isEmpty || value.length > maxItems) {
      throw FormatException('campo "$field" vazio ou com itens demais');
    }
    return value;
  }
}
