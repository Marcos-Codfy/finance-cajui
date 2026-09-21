import 'dart:convert';
import 'dart:io';

import 'package:persistence/src/event_store.dart';
import 'package:persistence/src/log_integrity_exception.dart';
import 'package:persistence/src/log_line.dart';
import 'package:persistence/src/log_reader.dart';
import 'package:persistence/src/record_cipher.dart';
import 'package:persistence/src/record_tampered_exception.dart';
import 'package:persistence/src/stored_event.dart';

/// O registro de eventos em arquivos JSON Lines, um por ano, cifrado por
/// registro e encadeado por hash (ADR-004 e ADR-005).
///
/// Há **um único escritor**: as gravações entram numa fila e acontecem uma de
/// cada vez. Cada uma é `append` + `fsync` antes de responder. O estado vive
/// em memória, reconstruído ao abrir.
final class FileEventStore implements EventStore {
  new _(this._directory, this._cipher, this._now, this._lastHash);

  final Directory _directory;
  final RecordCipher _cipher;
  final DateTime Function() _now;
  final List<StoredEvent> _events = [];
  final Map<String, StoredEvent> _byId = {};
  String _lastHash;
  Future<void> _queue = Future.value();

  @override
  List<StoredEvent> get events => List.unmodifiable(_events);

  /// Abre o registro em [directory], conferindo a cadeia e decifrando cada
  /// evento. Lança [LogIntegrityException] se algo não conferir.
  static Future<FileEventStore> open(
    Directory directory,
    RecordCipher cipher, {
    DateTime Function()? now,
  }) async {
    directory.createSync(recursive: true);
    final scan = LogReader.scan(directory);
    final torn = scan.tornFile;
    if (torn != null) {
      // O processo morreu no meio de uma escrita: a linha pela metade nunca
      // foi confirmada a ninguém, e é cortada fora.
      torn.openSync(mode: FileMode.append)
        ..truncateSync(scan.tornValidLength!)
        ..closeSync();
    }
    final store = FileEventStore._(
      directory,
      cipher,
      now ?? () => DateTime.now().toUtc(),
      scan.lastHash,
    );
    for (final line in scan.lines) {
      store._remember(await store._decrypt(line));
    }
    return store;
  }

  Future<StoredEvent> _decrypt(LogLine line) async {
    try {
      final plaintext = await _cipher.open(
        nonce: line.nonce,
        sealed: line.sealed,
        associated: LogLine.associatedData(
          line.version,
          line.seq,
          line.previousHash,
        ),
      );
      final json = jsonDecode(utf8.decode(plaintext)) as Map<String, Object?>;
      return StoredEvent.fromJson(line.seq, json);
    } on RecordTamperedException {
      throw LogIntegrityException(
        seq: line.seq,
        reason: 'o conteúdo não abre: foi alterado, ou a chave é outra',
      );
    }
  }

  void _remember(StoredEvent event) {
    _events.add(event);
    _byId[event.id] = event;
  }

  @override
  Future<StoredEvent> append({
    required String id,
    required String type,
    required Map<String, Object?> payload,
    int schema = 1,
  }) {
    final result = _queue.then(
      (_) => _write(id: id, type: type, payload: payload, schema: schema),
    );
    // A fila segue mesmo que esta gravação falhe: o erro é de quem a pediu.
    _queue = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  Future<StoredEvent> _write({
    required String id,
    required String type,
    required Map<String, Object?> payload,
    required int schema,
  }) async {
    final existing = _byId[id];
    if (existing != null) return existing;
    final event = StoredEvent(
      seq: _events.length + 1,
      id: id,
      type: type,
      at: _now(),
      schema: schema,
      payload: payload,
    );
    final line = await _seal(event);
    await _appendLine(LogReader.fileFor(_directory, event.at.year), line);
    _lastHash = LogLine.hashOf(line);
    _remember(event);
    return event;
  }

  Future<String> _seal(StoredEvent event) async {
    final box = await _cipher.seal(
      utf8.encode(event.toPlaintext()),
      associated: LogLine.associatedData(_cipher.version, event.seq, _lastHash),
    );
    return LogLine(
      version: _cipher.version,
      seq: event.seq,
      previousHash: _lastHash,
      nonce: box.nonce,
      sealed: box.sealed,
    ).encode();
  }

  /// `append` + `fsync`: só depois disto o evento existe.
  Future<void> _appendLine(File file, String line) async {
    final handle = await file.open(mode: FileMode.append);
    try {
      await handle.writeString('$line\n');
      await handle.flush();
    } finally {
      await handle.close();
    }
  }

  @override
  Future<void> close() => _queue;
}
