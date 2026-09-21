import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tocador de mentira: só anota o que foi pedido.
class _RecordingPlayer implements SoundPlayer {
  final List<(CajuiSound, double, double)> played = [];

  @override
  Future<void> preload() async {}

  @override
  void play(CajuiSound sound, {required double volume, required double rate}) =>
      played.add((sound, volume, rate));

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final haptics = <String>[];

  setUp(() {
    haptics.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String);
          }
          return null;
        });
  });

  group('SoundSettings', () {
    test('RNF-A11Y-17 o som nasce desligado', () {
      const settings = SoundSettings();

      expect(settings.soundEnabled, isFalse);
      expect(settings.allows(SoundCategory.touches), isFalse);
    });
  });

  group('SoundAndHapticFeedback', () {
    test('com o som desligado, nada toca, mas o toque responde', () {
      final player = _RecordingPlayer();
      SoundAndHapticFeedback(player: player).tap();

      expect(player.played, isEmpty);
      expect(haptics, hasLength(1));
    });

    test('com o som ligado, o mesmo som nunca toca duas vezes igual', () {
      final player = _RecordingPlayer();
      final feedback = SoundAndHapticFeedback(
        player: player,
        settings: const SoundSettings(soundEnabled: true),
      );

      for (var i = 0; i < 3; i++) {
        feedback.tap();
      }

      final rates = player.played.map((play) => play.$3).toList();
      expect(rates.toSet(), hasLength(3));
      expect(rates.every((rate) => (rate - 1).abs() <= 0.03), isTrue);
    });

    test('cada família liga e desliga sozinha', () {
      final player = _RecordingPlayer();
      SoundAndHapticFeedback(
          player: player,
          settings: const SoundSettings(
            soundEnabled: true,
            categories: {SoundCategory.confirmations},
          ),
        )
        ..tap()
        ..saved();

      expect(player.played.map((play) => play.$1), [CajuiSound.saved]);
    });

    test('o aviso usa a nota macia: não existe som de erro', () {
      final player = _RecordingPlayer();
      SoundAndHapticFeedback(
        player: player,
        settings: const SoundSettings(soundEnabled: true),
      ).notice();

      expect(player.played.single.$1, CajuiSound.notice);
      expect(
        CajuiSound.values.map((sound) => sound.name),
        isNot(contains('error')),
      );
    });

    test('resposta tátil desligada não vibra', () {
      SoundAndHapticFeedback(
        player: _RecordingPlayer(),
        settings: const SoundSettings(hapticsEnabled: false),
      ).saved();

      expect(haptics, isEmpty);
    });
  });

  group('CajuiSound', () {
    test('todo token aponta para um arquivo do pacote', () {
      for (final sound in CajuiSound.values) {
        expect(
          sound.asset,
          startsWith('packages/design_system/assets/sounds/'),
        );
        expect(sound.asset, endsWith('.wav'));
      }
    });
  });
}
