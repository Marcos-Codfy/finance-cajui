import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A chegada pelo widget da tela inicial: quantas vezes o número do widget
/// foi tocado nesta sessão.
///
/// A casca do app leva a pessoa ao Início a cada chegada, e o Início passa
/// o número a `CajuiGlassArrival`, que encena a chegada a cada valor novo —
/// o app crescendo de dentro do widget e o número atravessando o vidro
/// (pedido do dono, 12/10/2026).
class WidgetArrival extends Notifier<int> {
  /// O pedido que o lado nativo manda quando o número do widget é tocado —
  /// o contrato com `MainActivity.WIDGET_ROUTE`.
  static const route = 'widget';

  @override
  int build() => 0;

  /// Mais uma chegada.
  void arrive() => state = state + 1;

  /// Conta a chegada, se [requested] é o pedido do widget. Devolve se o
  /// pedido era dele.
  static bool open(WidgetRef ref, String requested) {
    if (requested != route) return false;
    ref.read(widgetArrivalProvider.notifier).arrive();
    return true;
  }
}

/// As chegadas pelo widget nesta sessão.
final widgetArrivalProvider = NotifierProvider<WidgetArrival, int>(
  WidgetArrival.new,
);
