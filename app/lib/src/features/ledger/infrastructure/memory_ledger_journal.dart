import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_journal.dart';

/// O livro guardado só na memória: some quando o app fecha.
///
/// É o que a web usa — lá o Cajui é modo consulta, e guardar dado financeiro
/// no armazenamento do navegador seria deixá-lo ao alcance de qualquer
/// extensão (ADR-013). Serve também aos testes.
final class MemoryLedgerJournal implements LedgerJournal {
  /// Cria o livro, já com [events] se houver.
  new([List<LedgerEvent> events = const []]) : _events = [...events];

  final List<LedgerEvent> _events;

  @override
  Future<List<LedgerEvent>> readAll() async => List.unmodifiable(_events);

  @override
  Future<void> append(LedgerEvent event) async {
    // O mesmo `id` duas vezes é a mesma gravação repetida, não outro fato.
    if (_events.any((known) => known.id == event.id)) return;
    _events.add(event);
  }
}
