import 'dart:async';

import 'package:cajui/src/core/settings/preferences_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Se o app está no tema escuro.
///
/// O padrão é o **tema claro**, e não o do aparelho: o Cajui é um app de
/// dinheiro, muitas vezes aberto no caixa do mercado, e o claro é o que se
/// lê no sol. O escuro fica a um toque, nos ajustes, para quem prefere.
class AppearanceController extends Notifier<bool> {
  @override
  bool build() => ref.read(preferencesStoreProvider).read().dark;

  /// Liga ou desliga o tema escuro. Vale na hora, sem botão de salvar — e
  /// continua valendo amanhã.
  ///
  /// A tela muda **antes** de a gravação terminar: escolha que demora a
  /// valer parece não ter valido.
  void setDark({required bool enabled}) {
    state = enabled;
    unawaited(
      ref
          .read(preferencesStoreProvider)
          .update((atual) => atual.copyWith(dark: enabled)),
    );
  }
}

/// Se o tema escuro está ligado.
final appearanceProvider = NotifierProvider<AppearanceController, bool>(
  AppearanceController.new,
);
