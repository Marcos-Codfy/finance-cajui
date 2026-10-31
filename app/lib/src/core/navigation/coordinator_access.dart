import 'package:cajui/src/core/navigation/navigation_providers.dart';
import 'package:cajui/src/core/navigation/scene_navigator.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Chega ao coordinator a partir de um `BuildContext`, para quem não tem `ref`.
///
/// Uma tela de lista é um `StatelessWidget` que só desenha: trocá-la por um
/// `ConsumerWidget` só para abrir outra tela seria ruído. O coordinator é
/// lido na hora do toque e nunca observado, então a tela não reconstrói por
/// causa dele.
extension CoordinatorAccess on BuildContext {
  /// O coordinator que [provider] entrega.
  T coordinator<T>(Provider<T> provider) =>
      ProviderScope.containerOf(this, listen: false).read(provider);

  /// Quem abre e fecha telas. Serve a quem precisa fechar com um resultado,
  /// ou antes de um `await`, quando o `context` já não vale.
  SceneNavigator get navigator => coordinator(sceneNavigatorProvider);

  /// Fecha a tela atual: a seta de voltar de toda tela passa por aqui.
  void back() => navigator.pop();
}
