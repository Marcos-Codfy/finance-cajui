import 'dart:async';

import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O dia de hoje, que vira sozinho com o app aberto.
///
/// O Android mantém o app vivo por dias. Lido uma vez, o dia ficava
/// parado: o Início mostrava o mês passado, a Juju falava de ontem e o
/// widget expirava sem ser refeito. Agora o dia é conferido a
/// cada minuto com o app aberto e quando ele volta à frente.
class TodayController extends Notifier<LocalDate> {
  /// De quanto em quanto tempo o dia é conferido.
  static const Duration checkEvery = Duration(minutes: 1);

  @override
  LocalDate build() {
    final clock = ref.watch(clockProvider);
    final timer = Timer.periodic(checkEvery, (_) => check());
    ref.onDispose(timer.cancel);
    return clock.today();
  }

  /// Confere o dia; se virou, quem depende dele é refeito.
  void check() {
    final day = ref.read(clockProvider).today();
    if (day != state) state = day;
  }
}

/// O dia de hoje para as telas e as contas.
final todayProvider = NotifierProvider<TodayController, LocalDate>(
  TodayController.new,
);
