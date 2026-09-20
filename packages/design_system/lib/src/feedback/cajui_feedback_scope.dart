import 'package:design_system/src/feedback/cajui_feedback.dart';
import 'package:design_system/src/feedback/silent_feedback.dart';
import 'package:flutter/widgets.dart';

/// Entrega aos componentes a resposta sonora e tátil em vigor.
///
/// Sem nenhum escopo na árvore, vale o silêncio — nunca um erro. Um botão tem
/// de funcionar igual com ou sem som.
class CajuiFeedbackScope extends InheritedWidget {
  /// Disponibiliza [feedback] para [child] e seus descendentes.
  const new({required this.feedback, required super.child, super.key});

  /// A resposta em vigor.
  final CajuiFeedback feedback;

  /// A resposta mais próxima acima de [context], ou o silêncio.
  static CajuiFeedback of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<CajuiFeedbackScope>();
    return scope?.feedback ?? const SilentFeedback();
  }

  @override
  bool updateShouldNotify(CajuiFeedbackScope oldWidget) =>
      feedback != oldWidget.feedback;
}
