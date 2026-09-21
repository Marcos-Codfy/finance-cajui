import 'package:persistence/src/stored_event.dart';

/// Onde os eventos moram. É a porta que o resto do sistema conhece (ADR-004):
/// hoje a implementação é um arquivo JSON Lines; se um dia for SQLite, quem
/// usa esta interface não muda uma linha.
abstract interface class EventStore {
  /// Todos os eventos, na ordem em que foram gravados.
  List<StoredEvent> get events;

  /// Grava um evento no fim do registro e só devolve depois que ele está
  /// **no disco** — é aí que o servidor pode responder "salvo".
  ///
  /// [id] é a chave de idempotência: gravar de novo um `id` que já existe
  /// não cria outro evento; devolve o que já estava lá. É o que torna segura
  /// a nova tentativa de um comando cuja resposta se perdeu (ADR-012).
  Future<StoredEvent> append({
    required String id,
    required String type,
    required Map<String, Object?> payload,
    int schema = 1,
  });

  /// Libera os arquivos abertos.
  Future<void> close();
}
