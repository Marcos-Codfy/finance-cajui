import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:persistence/persistence.dart';

/// As categorias e os lançamentos, reconstruídos a partir dos eventos.
///
/// O estado vive em memória e é uma **projeção**: apagado, refaz-se igual a
/// partir do registro. Nada aqui é fonte da verdade (ADR-004).
final class LedgerState {
  /// Reconstrói o estado aplicando os eventos [events], na ordem.
  new(Iterable<StoredEvent> events) {
    events.forEach(apply);
  }

  /// O tipo do evento de categoria criada.
  static const categoryCreated = 'category.created';

  /// O tipo do evento de lançamento criado.
  static const entryCreated = 'entry.created';

  final Map<String, Category> _categories = {};
  final List<Entry> _entries = [];

  /// As categorias, por identificador.
  Map<String, Category> get categories => Map.unmodifiable(_categories);

  /// Os lançamentos, na ordem em que entraram.
  List<Entry> get entries => List.unmodifiable(_entries);

  /// Aplica um evento ao estado. Tipo desconhecido é ignorado: um servidor
  /// mais velho consegue subir sobre um registro mais novo.
  void apply(StoredEvent event) {
    switch (event.type) {
      case categoryCreated:
        final category = categoryFrom(event.payload);
        _categories[category.id] = category;
      case entryCreated:
        _entries.add(_replayed(event));
    }
  }

  /// A categoria descrita por [json].
  static Category categoryFrom(Map<String, Object?> json) => Category(
    id: json['id']! as String,
    name: json['name']! as String,
    block: EntryCodec.named(Block.values, json['block']! as String),
    groupId: json['groupId']! as String,
    voucherEligible: json['voucherEligible'] as bool? ?? false,
  );

  /// O evento já foi aceito quando aconteceu; reaplicá-lo não pode falhar por
  /// causa do relógio. Por isso "hoje", aqui, é o dia seguinte ao do evento.
  Entry _replayed(StoredEvent event) {
    final today = LocalDate.fromDateTime(event.at).addDays(1);
    final request = CreateEntryRequest.fromJson(event.payload);
    return tryCreate(request, today: today).valueOrNull!;
  }

  /// Aplica as regras do domínio ao pedido [request]. É o servidor validando
  /// **de novo** o que o app já validou: nunca se confia no cliente (T-05).
  Result<Entry> tryCreate(
    CreateEntryRequest request, {
    required LocalDate today,
  }) {
    return EntryCodec.toEntry(
      request,
      category: _categories[request.categoryId]!,
      today: today,
    );
  }

  /// A mesma leitura de data do contrato; fica aqui para as rotas que
  /// recebem data fora de um lançamento.
  static LocalDate parseDate(String text) => EntryCodec.parseDate(text);
}
