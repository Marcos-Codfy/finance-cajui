import 'package:cajui/src/core/navigation/scene_navigator.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// O `SceneNavigator` de verdade: fala com o `Navigator` do app pela chave
/// que a raiz entregou ao `WidgetsApp`, sem precisar de `BuildContext`.
///
/// Quem navega não depende de estar dentro da árvore da tela: um ViewModel
/// ou uma notificação pode pedir a abertura de uma cena (ADR-031).
final class KeySceneNavigator implements SceneNavigator {
  /// Cria o navegador sobre a chave do `Navigator` raiz.
  const new(this._key);

  final GlobalKey<NavigatorState> _key;

  // Antes do primeiro quadro não há `Navigator`, e então não há o que abrir.
  @override
  Future<T?> push<T>(Widget scene) =>
      _key.currentState?.push<T>(CajuiPageRoute<T>(builder: (_) => scene)) ??
      Future<T?>.value();

  @override
  Future<T?> pushSheet<T>(Widget sheet) =>
      _key.currentState?.push<T>(CajuiSheetRoute<T>(builder: (_) => sheet)) ??
      Future<T?>.value();

  @override
  void pop([Object? result]) => _key.currentState?.pop<Object?>(result);

  @override
  void popToRoot() => _key.currentState?.popUntil((route) => route.isFirst);
}
