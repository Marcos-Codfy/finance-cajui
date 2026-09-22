import 'package:cajui/src/core/appearance/appearance_controller.dart';
import 'package:cajui/src/core/feedback/sound_settings_controller.dart';
import 'package:cajui/src/core/settings/event_store_preferences.dart';
import 'package:cajui/src/core/settings/preferences.dart';
import 'package:cajui/src/core/settings/preferences_store.dart';
import 'package:cajui/src/core/storage/memory_event_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/mute_player.dart';
import '../support/test_scope.dart';

/// BL-030 · a escolha tem de continuar valendo amanhã.
///
/// Som, vibração e tema viviam só na memória: fechar o app apagava tudo, e
/// quem ligava o som ligava de novo toda vez — até desistir.
void main() {
  late MemoryEventStore store;
  late ProviderContainer container;

  ProviderContainer abrir() => ProviderContainer(
    overrides: [
      ...testOverrides(
        player: MutePlayer(),
        preferences: EventStorePreferences(store),
      ),
    ],
  );

  setUp(() {
    store = MemoryEventStore();
    container = abrir();
    addTearDown(container.dispose);
  });

  test('o tema escolhido volta na abertura seguinte', () async {
    container.read(appearanceProvider.notifier).setDark(enabled: true);
    await _gravado(container);

    final depois = abrir();
    addTearDown(depois.dispose);

    expect(depois.read(appearanceProvider), isTrue);
  });

  test('som e vibração voltam como foram deixados', () async {
    container.read(soundSettingsProvider.notifier).setSound(enabled: true);
    container.read(soundSettingsProvider.notifier).setHaptics(enabled: false);
    await _gravado(container);

    final depois = abrir();
    addTearDown(depois.dispose);
    final settings = depois.read(soundSettingsProvider);

    expect(settings.soundEnabled, isTrue);
    expect(settings.hapticsEnabled, isFalse);
  });

  test('mudar uma escolha não derruba a outra', () async {
    container.read(soundSettingsProvider.notifier).setSound(enabled: true);
    container.read(appearanceProvider.notifier).setDark(enabled: true);
    await _gravado(container);

    final depois = abrir();
    addTearDown(depois.dispose);

    expect(depois.read(soundSettingsProvider).soundEnabled, isTrue);
    expect(depois.read(appearanceProvider), isTrue);
  });

  test('sem nada gravado, valem os padrões: som desligado, tema claro', () {
    expect(EventStorePreferences(MemoryEventStore()).read(), _padrao);
  });

  test('registro de uma versão mais velha continua servindo', () {
    // Campo que falta volta ao padrão, em vez de estourar.
    expect(Preferences.fromJson(const {'dark': true}).dark, isTrue);
    expect(Preferences.fromJson(const {'dark': true}).hapticsEnabled, isTrue);
    expect(Preferences.fromJson(const {}), _padrao);
  });

  test(
    'duas escolhas seguidas gravam as duas (chave não é o relógio)',
    () async {
      // Com o relógio como chave, dois toques no mesmo milissegundo viravam a
      // mesma chave e o segundo era descartado como repetido.
      final PreferencesStore porta = EventStorePreferences(store);
      await Future.wait([
        porta.update((atual) => atual.copyWith(dark: true)),
        porta.update((atual) => atual.copyWith(soundEnabled: true)),
      ]);

      expect(store.events, hasLength(2));
      expect(porta.read().dark, isTrue);
      expect(porta.read().soundEnabled, isTrue);
    },
  );

  test('nada disso é fato financeiro: só um tipo de evento entra', () async {
    final PreferencesStore porta = EventStorePreferences(store);
    await porta.update((atual) => atual.copyWith(dark: true));

    expect(store.events.single.type, EventStorePreferences.changed);
  });
}

const _padrao = Preferences();

/// Espera a fila de gravação esvaziar.
///
/// A porta enfileira uma mudança por vez, então uma mudança vazia posta no
/// fim só termina quando as anteriores terminaram. É espera de verdade, e
/// não um punhado de voltas do laço de eventos torcendo para dar tempo.
Future<void> _gravado(ProviderContainer container) =>
    container.read(preferencesStoreProvider).update((atual) => atual);
