/// O registro de eventos do Cajui e os seus resumos.
///
/// Quem usa conhece só as portas `EventStore` e `SnapshotStore`; os arquivos
/// JSON Lines, a cifra por registro e a cadeia de hash são detalhe daqui
/// (ADR-004 e ADR-005).
library;

export 'src/aes_gcm_record_cipher.dart';
export 'src/data_key.dart';
export 'src/db_tool.dart';
export 'src/event_store.dart';
export 'src/file_event_store.dart';
export 'src/file_snapshot_store.dart';
export 'src/log_integrity_exception.dart';
export 'src/log_line.dart';
export 'src/log_reader.dart';
export 'src/log_scan.dart';
export 'src/record_cipher.dart';
export 'src/record_tampered_exception.dart';
export 'src/snapshot_store.dart';
export 'src/storage_full_exception.dart';
export 'src/stored_event.dart';
