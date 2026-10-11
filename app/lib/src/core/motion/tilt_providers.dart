import 'package:cajui/src/core/motion/no_tilt_source.dart';
import 'package:cajui/src/core/motion/tilt_source.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A fonte da inclinação. A raiz de composição liga o acelerômetro no
/// Android; no resto, nada.
final tiltSourceProvider = Provider<TiltSource>((ref) => const NoTiltSource());

/// A inclinação enquanto alguma tela à vista a pedir. Ninguém pedindo, o
/// sensor para: bateria não é gasta com enfeite que ninguém vê.
final Provider<CajuiTilt?> deviceTiltProvider =
    Provider.autoDispose<CajuiTilt?>((ref) {
      final reading = ref.watch(tiltSourceProvider).open();
      if (reading == null) return null;
      ref.onDispose(reading.close);
      return reading.tilt;
    });
