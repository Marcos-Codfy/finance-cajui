import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/receipts/application/capture.dart';
import 'package:meta/meta.dart';

/// O que saiu de abrir um item compartilhado.
@immutable
sealed class CaptureOutcome {
  const new();
}

/// Deu para ler e classificar: há uma proposta para conferir.
final class CaptureProposed extends CaptureOutcome {
  /// Cria o resultado com a captura [capture].
  const new(this.capture);

  /// A captura, pronta para a tela de confirmação.
  final Capture capture;
}

/// Não deu, pelo motivo [code] do catálogo. O arquivo, se havia, continua
/// guardado: a pessoa ainda pode digitar os dados com ele anexado.
final class CaptureRefused extends CaptureOutcome {
  /// Cria a recusa de código [code].
  const new(this.code, {this.detail = const {}});

  /// O código `E-CAPT-NN`.
  final ErrorCode code;

  /// Os valores que o texto do erro usa.
  final Map<String, Object?> detail;
}
