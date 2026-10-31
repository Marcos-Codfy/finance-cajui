import 'package:cajui/src/core/navigation/scene_navigator.dart';
import 'package:flutter/widgets.dart';

/// Um navegador de mentira: não desenha tela nenhuma, só anota o que lhe
/// pediram. Serve para provar **para onde** um coordinator leva, sem montar a
/// árvore de widgets (ADR-031).
final class RecordingSceneNavigator implements SceneNavigator {
  /// Cria o navegador. [answer] é o que as telas empilhadas "devolvem".
  new({this.answer});

  /// O que `push` e `pushSheet` entregam a quem espera a tela fechar.
  final Object? answer;

  /// As telas empilhadas, na ordem.
  final pushed = <Widget>[];

  /// Os painéis empilhados, na ordem.
  final sheets = <Widget>[];

  /// Os resultados de cada `pop`.
  final popped = <Object?>[];

  /// Quantas vezes se voltou à casca.
  int toRoot = 0;

  @override
  Future<T?> push<T>(Widget scene) async {
    pushed.add(scene);
    return answer as T?;
  }

  @override
  Future<T?> pushSheet<T>(Widget sheet) async {
    sheets.add(sheet);
    return answer as T?;
  }

  @override
  void pop([Object? result]) => popped.add(result);

  @override
  void popToRoot() => toRoot++;
}
