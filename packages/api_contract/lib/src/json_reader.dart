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

  /// Um inteiro opcional; ausente ou nulo devolve `null`.
  int? optionalInteger(String field) =>
      _json[field] == null ? null : _read<int>(field);

  /// Um instante ISO 8601 opcional, devolvido em UTC. Carimbo ilegível
  /// vale como nenhum: quem o carrega continua valendo, só perde a vez na
  /// disputa entre dois aparelhos.
  DateTime? optionalInstant(String field) =>
      instantOf(optionalString(field, maxLength: 40));

  /// O instante em [raw], em UTC, quando dá para ler. **Sem fuso explícito
  /// não se lê**: `DateTime.parse` tomaria a hora como local, e um servidor
  /// em outro fuso a deslocaria — três horas decidem quem venceu.
  static DateTime? instantOf(Object? raw) {
    if (raw is! String || !_withOffset.hasMatch(raw)) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  static final _withOffset = RegExp(r'(Z|[+-]\d{2}:?\d{2})$');

  /// Um texto opcional; ausente, nulo ou vazio devolve `null`.
  String? optionalString(String field, {int maxLength = 200}) {
    if (_json[field] == null) return null;
    final value = _read<String>(field).trim();
    return value.isEmpty || value.length > maxLength ? null : value;
  }

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

  /// Uma lista opcional; ausente ou nula devolve a lista vazia.
  ///
  /// Existe para o que pode legitimamente estar vazio — quem não cadastrou
  /// nenhuma conta fixa ainda tem um plano válido. O teto de [maxItems]
  /// continua: o limite de tamanho do corpo sozinho deixaria passar milhares
  /// de itens minúsculos.
  List<Object?> optionalList(String field, {int maxItems = 50}) {
    if (_json[field] == null) return const [];
    final value = _read<List<Object?>>(field);
    if (value.length > maxItems) {
      throw FormatException('campo "$field" com itens demais');
    }
    return value;
  }
}
