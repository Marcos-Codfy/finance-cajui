import 'package:design_system/src/feedback/cajui_feedback.dart';

/// A resposta que não faz nada. É o padrão: o som nasce desligado, e teste
/// de widget não deve depender de áudio nem de vibração.
class SilentFeedback implements CajuiFeedback {
  /// Cria a resposta silenciosa.
  const new();

  @override
  void tap() {}

  @override
  void toggle({required bool on}) {}

  @override
  void open() {}

  @override
  void saved() {}

  @override
  void notice() {}

  @override
  void achievement() {}
}
