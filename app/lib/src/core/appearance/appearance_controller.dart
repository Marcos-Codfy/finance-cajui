import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Se o app está no tema escuro.
///
/// O padrão é o **tema claro**, e não o do aparelho: o Cajui é um app de
/// dinheiro, muitas vezes aberto no caixa do mercado, e o claro é o que se
/// lê no sol. O escuro fica a um toque, nos ajustes, para quem prefere.
class AppearanceController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Liga ou desliga o tema escuro. Vale na hora, sem botão de salvar.
  ///
  /// Método, e não setter: `setDark(enabled: true)` diz o que acontece na
  /// chamada, como o controlador de som ao lado.
  // ignore: use_setters_to_change_properties
  void setDark({required bool enabled}) => state = enabled;
}

/// Se o tema escuro está ligado.
final appearanceProvider = NotifierProvider<AppearanceController, bool>(
  AppearanceController.new,
);
