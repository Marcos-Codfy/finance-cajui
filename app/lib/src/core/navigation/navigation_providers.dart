import 'package:cajui/src/core/navigation/key_scene_navigator.dart';
import 'package:cajui/src/core/navigation/scene_navigator.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A chave do `Navigator` raiz. A raiz do app a entrega ao `WidgetsApp`, e o
/// [sceneNavigatorProvider] a usa para abrir e fechar telas.
final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (ref) => GlobalKey<NavigatorState>(debugLabel: 'cajui'),
);

/// Quem abre e fecha telas. O teste troca por um navegador que só anota.
final sceneNavigatorProvider = Provider<SceneNavigator>(
  (ref) => KeySceneNavigator(ref.watch(navigatorKeyProvider)),
);
