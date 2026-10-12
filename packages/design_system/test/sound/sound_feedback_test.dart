import 'dart:io';
import 'dart:typed_data';

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
      // Peso de tecla de teclado, e não o tique de rolagem: no aparelho o
      // `selectionClick` não se sentia.
      expect(haptics.single, 'HapticFeedbackType.lightImpact');
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

    test('lançar toca a semente e desfazer toca a folha, com pulso leve', () {
      final player = _RecordingPlayer();
      SoundAndHapticFeedback(
          player: player,
          settings: const SoundSettings(soundEnabled: true),
        )
        ..entrySaved()
        ..undone();

      expect(player.played.map((play) => play.$1), [
        CajuiSound.entrySaved,
        CajuiSound.undone,
      ]);
      // Lançar se repete o dia inteiro: o pulso é o de tecla, nunca o médio.
      expect(haptics, [
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.lightImpact',
      ]);
    });

    test('semente e folha são confirmações: desligar a família as cala', () {
      final player = _RecordingPlayer();
      SoundAndHapticFeedback(
          player: player,
          settings: const SoundSettings(
            soundEnabled: true,
            categories: {SoundCategory.touches},
          ),
        )
        ..entrySaved()
        ..undone();

      expect(player.played, isEmpty);
      expect(haptics, hasLength(2));
    });

    test('a página do carrossel encaixa com o deslize, que é de ambiente', () {
      final player = _RecordingPlayer();
      final feedback = SoundAndHapticFeedback(
        player: player,
        settings: const SoundSettings(soundEnabled: true),
      )..pageTurned();

      expect(player.played.single.$1, CajuiSound.swipe);
      expect(haptics, ['HapticFeedbackType.lightImpact']);

      // Quem folheia muito cala só o ambiente; o pulso continua.
      player.played.clear();
      feedback
        ..settings = const SoundSettings(
          soundEnabled: true,
          categories: {SoundCategory.touches, SoundCategory.confirmations},
        )
        ..pageTurned();
      expect(player.played, isEmpty);
      expect(haptics, hasLength(2));
    });

    test('cada família de toque tem o seu arquivo: botão, card, tecla e '
        'chave', () {
      final player = _RecordingPlayer();
      SoundAndHapticFeedback(
          player: player,
          settings: const SoundSettings(soundEnabled: true),
        )
        ..tap()
        ..cardTapped()
        ..keyTyped()
        ..toggle(on: true)
        ..toggle(on: false);

      expect(player.played.map((play) => play.$1), [
        CajuiSound.tap,
        CajuiSound.card,
        CajuiSound.key,
        CajuiSound.toggleOn,
        CajuiSound.toggleOff,
      ]);
      // A tecla não vibra: o teclado do telefone já vibra a cada letra.
      expect(haptics, hasLength(4));
    });

    test('card e tecla são toques: desligar a família os cala', () {
      final player = _RecordingPlayer();
      SoundAndHapticFeedback(
          player: player,
          settings: const SoundSettings(
            soundEnabled: true,
            categories: {SoundCategory.confirmations, SoundCategory.ambient},
          ),
        )
        ..cardTapped()
        ..keyTyped();

      expect(player.played, isEmpty);
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

    test('todo token tem o arquivo de verdade, curto e leve', () {
      // O caminho do token sem o prefixo de pacote é o caminho no disco.
      for (final sound in CajuiSound.values) {
        final file = File(
          sound.asset.replaceFirst('packages/design_system/', ''),
        );

        expect(file.existsSync(), isTrue, reason: sound.asset);
        // 60 KB cabem 680 ms de mono a 16 bits: nenhum som chega perto.
        expect(file.lengthSync(), lessThan(60 * 1024), reason: sound.asset);
      }
    });

    test('todo arquivo é mono, 16 bits, 44,1 kHz; o de toque começa a soar nos '
        'primeiros 5 ms — som atrasado em relação ao dedo é pior que nenhum —, '
        'e os outros em 10', () {
      for (final sound in CajuiSound.values) {
        final bytes = File(
          sound.asset.replaceFirst('packages/design_system/', ''),
        ).readAsBytesSync().buffer.asByteData();

        expect(bytes.getUint16(22, Endian.little), 1, reason: sound.asset);
        expect(bytes.getUint32(24, Endian.little), 44100, reason: sound.asset);
        expect(bytes.getUint16(34, Endian.little), 16, reason: sound.asset);
        // A folha do desfazer cresce de propósito: não responde ao dedo,
        // que já ouviu o clique do botão.
        final limit = sound.category == SoundCategory.touches ? 5 : 10;
        expect(_onsetMs(bytes), lessThan(limit), reason: sound.asset);
      }
    });
  });
}

/// Onde o som começa, em milissegundos: a primeira amostra acima de 3% do
/// pico. Os dados vêm depois do cabeçalho de 44 bytes, em 16 bits.
double _onsetMs(ByteData wav) {
  final samples = [
    for (var at = 44; at + 1 < wav.lengthInBytes; at += 2)
      wav.getInt16(at, Endian.little).abs(),
  ];
  final peak = samples.reduce((a, b) => a > b ? a : b);
  final first = samples.indexWhere((sample) => sample > peak * 0.03);
  return first / 44.1;
}
