import 'package:api_contract/api_contract.dart';
import 'package:meta/meta.dart';

/// O que saiu da leitura de um comprovante.
@immutable
sealed class ReadOutcome {
  const new();
}

/// O texto lido, ainda sujo: é dado não confiável até o domínio limpar.
final class ReadText extends ReadOutcome {
  /// Cria o resultado com o texto [text].
  const new(this.text);

  /// O texto como o OCR devolveu.
  final String text;
}

/// A leitura não deu certo, pelo motivo [code] do catálogo: sem texto
/// legível, PDF com senha, página que demorou demais.
final class ReadFailed extends ReadOutcome {
  /// Cria a falha de código [code].
  const new(this.code);

  /// `E-CAPT-01`, `E-CAPT-04` ou `E-CAPT-07`.
  final ErrorCode code;
}
