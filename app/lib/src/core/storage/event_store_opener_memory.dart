import 'package:cajui/src/core/storage/memory_event_store.dart';
import 'package:persistence/event_store.dart';

/// Na web, o registro vive só enquanto a aba está aberta (ADR-013).
Future<EventStore> openEventStore() async => MemoryEventStore();
