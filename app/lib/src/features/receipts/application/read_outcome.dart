import 'dart:typed_data';

import 'package:api_contract/api_contract.dart';
import 'package:meta/meta.dart';

/// O que saiu da leitura de um comprovante.
@immutable
sealed class ReadOutcome {
  const new();
}

/// O texto lido, ainda sujo: é dado não confiável até o domínio limpar.
/// Junto, as imagens do documento para a IA ler (ADR-022) — vazio quando o
/// que chegou foi texto.
final class ReadText extends ReadOutcome {
  /// Cria o resultado com o texto [text] e as imagens [images].
  const new(this.text, {this.images = const []});

  /// O texto como o OCR devolveu. Pode vir vazio: foto que o celular não
  /// conseguiu ler, mas que a IA ainda pode.
  final String text;

  /// A foto, ou as primeiras páginas do PDF, em JPEG.
  final List<Uint8List> images;
}

/// A leitura não deu certo, pelo motivo [code] do catálogo: sem texto
/// legível, PDF com senha, página que demorou demais.
final class ReadFailed extends ReadOutcome {
  /// Cria a falha de código [code].
  const new(this.code);

  /// `E-CAPT-01`, `E-CAPT-04` ou `E-CAPT-07`.
  final ErrorCode code;
}
