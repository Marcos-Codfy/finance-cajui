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

  /// O tipo do evento de cartão cadastrado.
  ///
  /// O servidor precisa dos cartões por um motivo só: **compra parcelada**.
  /// O plano de parcelas é recalculado a partir do cartão e da data — não
  /// se confia na parcela que o app mandou (T-05) —, e sem o cartão o
  /// domínio recusa o lançamento inteiro.
  static const cardDefined = 'card.defined';

  /// O tipo do evento de lançamento criado.
  static const entryCreated = 'entry.created';

  /// O tipo do evento de lançamento corrigido. **Nada é reescrito**
  /// (RN-208): o fato antigo continua no registro, e a projeção passa a
  /// mostrar o novo no lugar dele.
  static const entryRevised = 'entry.revised';

  /// O tipo do evento de lançamento cancelado. O cancelado sai de toda
  /// visão (RN-995), mas não some do registro.
  static const entryCancelled = 'entry.cancelled';

  final Map<String, Category> _categories = {};
  final Map<String, CreditCard> _cards = {};
  final List<Entry> _entries = [];

  /// As categorias, por identificador.
  Map<String, Category> get categories => Map.unmodifiable(_categories);

  /// Os cartões cadastrados, por identificador.
  Map<String, CreditCard> get cards => Map.unmodifiable(_cards);

  /// Os lançamentos, na ordem em que entraram.
  List<Entry> get entries => List.unmodifiable(_entries);

  /// Aplica um evento ao estado. Tipo desconhecido é ignorado: um servidor
  /// mais velho consegue subir sobre um registro mais novo.
  void apply(StoredEvent event) {
    switch (event.type) {
      case categoryCreated:
        final category = categoryFrom(event.payload);
        _categories[category.id] = category;
      case cardDefined:
        final card = CardCodec.decodeCard(event.payload);
        _cards[card.id] = card;
      case entryCreated:
        _entries.add(_replayed(event));
      case entryRevised:
        _replace(_replayed(event));
      case entryCancelled:
        _entries.removeWhere((entry) => entry.id == event.payload['id']);
    }
  }

  /// Põe [entry] no lugar da versão anterior, **na mesma posição**: corrigir
  /// um lançamento não o manda para o fim da lista.
  void _replace(Entry entry) {
    final at = _entries.indexWhere((existing) => existing.id == entry.id);
    if (at < 0) {
      _entries.add(entry);
      return;
    }
    _entries[at] = entry;
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
      // Sem isto, toda compra parcelada é recusada: o plano de parcelas é
      // **recalculado** a partir do cartão (T-05, nunca se confia na parcela
      // que o app mandou), e sem o cartão não há de onde recalcular.
      cardOf: (id) => _cards[id],
    );
  }

  /// A mesma leitura de data do contrato; fica aqui para as rotas que
  /// recebem data fora de um lançamento.
  static LocalDate parseDate(String text) => EntryCodec.parseDate(text);
}
