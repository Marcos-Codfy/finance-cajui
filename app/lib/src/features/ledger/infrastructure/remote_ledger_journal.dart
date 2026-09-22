import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_journal.dart';
import 'package:domain/domain.dart';

/// O livro visto de fora: os lançamentos que **o servidor** tem (ADR-013).
///
/// É o que a web usa. Ela não tem registro próprio — e o que ela tinha antes
/// era um livro vazio na memória, que mostrava "R$ 0,00" com cara de
/// verdade enquanto os lançamentos estavam no celular.
///
/// Só lê. `append` recusa por construção: a web é modo consulta, e isso não
/// se garante escondendo botão (T-12, RN-906) — se alguém chamar, estoura
/// aqui, e o teste pega.
final class RemoteLedgerJournal implements LedgerJournal {
  /// Cria o livro remoto sobre [_api].
  const new(this._api, {required this._categoryOf});

  final CajuiApi _api;
  final Category Function(String id) _categoryOf;

  @override
  Future<List<LedgerEvent>> readAll() async {
    final outcome = await _api.authenticated(
      (token) => _api.send('GET', '/v1/entries', token: token),
    );
    final lista = outcome.body?['entries'] as List<Object?>? ?? const [];
    return [
      // O plano vem antes dos lançamentos porque é o que dá sentido a eles:
      // sem ele a consulta mostra o que saiu, mas não quanto ainda cabe.
      ...await _plan(),
      for (final item in lista)
        if (_entryOf(item) case final entry?) EntryRecorded(entry),
    ];
  }

  /// Servidor que ainda não recebeu plano nenhum devolve um plano vazio, e
  /// aí não há fato a aplicar: o livro nasce sem plano, como no aparelho.
  Future<List<LedgerEvent>> _plan() async {
    final outcome = await _api.authenticated(
      (token) => _api.send('GET', '/v1/plan', token: token),
    );
    final body = outcome.body;
    if (body == null) return const [];
    final setup = MonthSetupCodec.decode(body);
    // O identificador é fixo porque aqui só existe um plano: o que o
    // servidor tem agora. A consulta não guarda o histórico dele.
    return setup.isEmpty
        ? const []
        : [PlanDefined(id: 'plan-remoto', setup: setup)];
  }

  /// Lançamento que o app não consegue reconstruir — categoria que ele não
  /// conhece, formato de um servidor mais novo — é **pulado**, e não derruba
  /// a tela inteira. Ver um mês quase completo é melhor que ver um erro.
  Entry? _entryOf(Object? item) {
    if (item is! Map) return null;
    try {
      final pedido = CreateEntryRequest.fromJson(item.cast<String, Object?>());
      return EntryCodec.toEntry(
        pedido,
        category: _categoryOf(pedido.categoryId),
        // O lançamento já foi aceito quando aconteceu: reconstruí-lo não
        // pode falhar por causa do relógio de quem está olhando.
        today: EntryCodec.parseDate(pedido.occurredOn).addDays(1),
      ).valueOrNull;
    } on Object {
      return null;
    }
  }

  @override
  Future<void> append(LedgerEvent event) =>
      throw StateError('A consulta não grava: lançar é no celular.');
}
