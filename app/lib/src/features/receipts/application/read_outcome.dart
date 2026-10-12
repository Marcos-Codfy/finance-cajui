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
  const new(
    this.text, {
    this.images = const [],
    this.pages = const [],
    this.pageCount,
    this.imagePages = const [],
  });

  /// O texto como o OCR devolveu. Pode vir vazio: foto que o celular não
  /// conseguiu ler, mas que a IA ainda pode.
  final String text;

  /// A foto, ou as primeiras páginas do PDF, em JPEG.
  final List<Uint8List> images;

  /// O texto de cada página lida, separado: o extrato é lido uma página
  /// por vez (ADR-030). Vazio quando o leitor não separou — e aí [text] é
  /// a página única.
  final List<String> pages;

  /// Quantas páginas o arquivo tem de verdade, mesmo as que não foram
  /// lidas: "Li as páginas 1 a 20 de 24" (RN-1101).
  final int? pageCount;

  /// A página de cada imagem de [images], a partir de 1. Vazio quando o
  /// leitor não disse, e aí a ordem das imagens é a das páginas.
  final List<int> imagePages;

  /// O texto de cada página, nunca vazio.
  List<String> get pageTexts => pages.isEmpty ? [text] : pages;

  /// A imagem da página [page] (a partir de 1), quando ela foi para a IA.
  Uint8List? imageOf(int page) {
    final at = imagePages.isEmpty ? page - 1 : imagePages.indexOf(page);
    return at >= 0 && at < images.length ? images[at] : null;
  }
}

/// A leitura não deu certo, pelo motivo [code] do catálogo: sem texto
/// legível, PDF com senha, página que demorou demais.
final class ReadFailed extends ReadOutcome {
  /// Cria a falha de código [code].
  const new(this.code);

  /// `E-CAPT-01`, `E-CAPT-04` ou `E-CAPT-07`.
  final ErrorCode code;
}
