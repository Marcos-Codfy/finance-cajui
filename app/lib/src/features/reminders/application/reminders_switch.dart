import 'dart:async';

import 'package:cajui/src/core/settings/preferences_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A chave "Lembrar das contas a vencer" (RN-1088): nasce ligada, vale na
/// hora e é lembrada entre aberturas, com as outras preferências.
///
/// É independente da revisão de domingo e do lançamento pelas notificações
/// do banco (RN-847): desligar uma não desliga a outra.
class RemindersSwitch extends Notifier<bool> {
  @override
  bool build() => ref.read(preferencesStoreProvider).read().remindDueBills;

  /// Liga ou desliga os lembretes. A lista do aparelho muda junto: quem
  /// publica observa esta chave.
  void set({required bool enabled}) {
    state = enabled;
    unawaited(
      ref
          .read(preferencesStoreProvider)
          .update((current) => current.copyWith(remindDueBills: enabled)),
    );
  }
}

/// Se os lembretes de vencimento estão ligados.
final remindersEnabledProvider = NotifierProvider<RemindersSwitch, bool>(
  RemindersSwitch.new,
);
