import 'package:cajui/src/core/storage/memory_event_store.dart';
import 'package:persistence/event_store.dart';

/// Na web, o registro vive só enquanto a aba está aberta (ADR-013).
Future<EventStore> openEventStore() async => MemoryEventStore();

/// Na web não há registro em disco para guardar de lado: recarregar a aba
/// já começa do zero, com os dados do servidor.
Future<void> setLedgerAside() async {}
