import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/features/receipts/application/capture.dart';
import 'package:meta/meta.dart';

/// Os estados da tela de captura (sharing-flow, "Os estados da tela"). A
/// tela faz `switch` exaustivo sobre eles (ADR-002).
@immutable
sealed class CaptureState {
  const new({this.waiting = 0});

  /// Quantos comprovantes ainda esperam na fila, depois deste (RN-705).
  final int waiting;
}

/// Nada chegando: a tela de captura não aparece.
final class CaptureIdle extends CaptureState {
  /// Cria o estado de repouso.
  const new();
}

/// Lendo o comprovante. Em PDF, [page] de [of] vem do trabalho
/// de verdade, e não de animação (RNF-PERF-06).
final class CaptureReading extends CaptureState {
  /// Cria o estado de leitura.
  const new({this.page, this.of, super.waiting});

  /// A página em leitura; `null` em imagem e texto.
  final int? page;

  /// O total de páginas.
  final int? of;
}

/// Há uma proposta para conferir.
final class CaptureReady extends CaptureState {
  /// Cria o estado de conferência de [capture].
  const new(this.capture, {super.waiting});

  /// A captura lida e classificada.
  final Capture capture;
}

/// Não deu para ler ou receber, pelo motivo em [error].
final class CaptureFailed extends CaptureState {
  /// Cria o estado de falha.
  const new(this.error, {super.waiting});

  /// O erro do catálogo, já com os valores no texto.
  final PresentedError error;
}
