import 'package:design_system/src/motion/frame_budget_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Escuta os tempos de quadro do aparelho e avisa, uma vez, quando ele deixa
/// de dar conta.
///
/// O rebaixamento é por medição no próprio aparelho, não por adivinhação de
/// modelo. Uma vez acusado, fica acusado até o fim da sessão: nível que sobe
/// e desce faz a interface piscar.
class FrameBudgetMonitor extends ChangeNotifier {
  /// Cria o monitor. [window] pode ser trocada em teste.
  new({FrameBudgetWindow? window}) : _window = window ?? FrameBudgetWindow();

  final FrameBudgetWindow _window;
  bool _dropping = false;
  bool _attached = false;

  /// Se o aparelho está perdendo quadros. Nunca volta a `false`.
  bool get framesAreDropping => _dropping;

  /// Começa a escutar os quadros.
  void attach() {
    if (_attached) return;
    _attached = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      record(timing.totalSpan);
    }
  }

  /// Registra um quadro. Público para o teste alimentar tempos fixos.
  void record(Duration frame) {
    if (_dropping) return;
    _window.record(frame);
    if (!_window.isDropping) return;
    _dropping = true;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_attached) SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    super.dispose();
  }
}
