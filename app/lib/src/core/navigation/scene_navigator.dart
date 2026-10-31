import 'package:flutter/widgets.dart';

/// Quem de fato empilha e fecha telas.
///
/// É a porta que os coordinators usam, e não o `Navigator` do Flutter: assim
/// um coordinator se testa sem desenhar tela nenhuma, com um navegador falso
/// que só anota o que foi pedido (ADR-031).
abstract interface class SceneNavigator {
  /// Abre [scene] por cima da tela atual e espera o que ela devolver ao
  /// fechar, ou `null` se foi fechada sem resposta.
  Future<T?> push<T>(Widget scene);

  /// Abre [sheet] como painel que sobe de baixo, com a tela de trás à vista.
  /// Serve às escolhas curtas, em que o que a pessoa digitou continua visível.
  Future<T?> pushSheet<T>(Widget sheet);

  /// Fecha a tela atual, devolvendo [result] a quem a abriu.
  void pop([Object? result]);

  /// Fecha tudo o que está empilhado e volta à casca do app.
  void popToRoot();
}
