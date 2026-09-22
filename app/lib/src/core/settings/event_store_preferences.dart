import 'package:cajui/src/core/settings/preferences.dart';
import 'package:cajui/src/core/settings/preferences_store.dart';
import 'package:persistence/event_store.dart';

/// As preferências guardadas no mesmo registro cifrado dos lançamentos.
///
/// Registro de acréscimo: mudar o tema não reescreve nada, grava um fato
/// novo — e **o último vale**. Custa uma linha por mudança de chave, que é
/// barato demais para justificar um segundo arquivo com um segundo jeito de
/// cifrar.
final class EventStorePreferences implements PreferencesStore {
  /// Cria a porta sobre [_store].
  new(this._store);

  /// O tipo do evento de preferência mudada.
  static const changed = 'settings.changed';

  final EventStore _store;

  /// A fila de gravação: uma mudança por vez, na ordem em que foi pedida.
  /// Sem ela, duas escolhas seguidas leriam o mesmo estado e a segunda
  /// gravaria por cima da primeira.
  Future<void> _fila = Future<void>.value();

  @override
  Preferences read() {
    final ultimo = _store.events.where((event) => event.type == changed);
    if (ultimo.isEmpty) return const Preferences();
    return Preferences.fromJson(ultimo.last.payload);
  }

  @override
  Future<void> update(Preferences Function(Preferences current) change) {
    // A leitura acontece **dentro da fila**, e não antes dela: é o que
    // garante que cada mudança parta do que a anterior deixou.
    return _fila = _fila.then((_) => _write(change(read())));
  }

  /// A chave de idempotência é **o tamanho do registro**, e não o relógio.
  ///
  /// Com o relógio, duas escolhas no mesmo milissegundo — dois toques
  /// seguidos em Ajustes — geravam a mesma chave, e a segunda era
  /// descartada como repetida. O registro só cresce, e a gravação acontece
  /// uma por vez dentro da fila: o tamanho não se repete.
  Future<void> _write(Preferences preferences) async {
    await _store.append(
      id: 'settings-${_store.events.length}',
      type: changed,
      payload: preferences.toJson(),
    );
  }
}
