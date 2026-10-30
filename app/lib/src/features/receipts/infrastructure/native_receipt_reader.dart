import 'dart:async';

import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/receipts/application/read_outcome.dart';
import 'package:cajui/src/features/receipts/application/receipt_reader.dart';
import 'package:cajui/src/features/receipts/application/shared_item.dart';
import 'package:flutter/services.dart';

/// A leitura feita pelo módulo nativo: ML Kit no aparelho, PDF rasterizado
/// pelo próprio Android (ADR-007). Pelo canal passa o caminho do arquivo, na
/// ida; na volta, o texto e a imagem já reduzida que a IA vai ver (ADR-022).
final class NativeReceiptReader implements ReceiptReader {
  /// Cria o leitor. [progress] é o fluxo de "página x de y" do lado nativo.
  const new({
    required this.progress,
    this.methods = const MethodChannel('app.cajui/capture'),
  });

  /// O progresso da leitura em curso.
  final Stream<(int page, int of)> progress;

  /// O canal de métodos do módulo nativo.
  final MethodChannel methods;

  @override
  Future<ReadOutcome> read(
    SharedFile file, {
    void Function(int page, int of)? onPage,
  }) async {
    final listening = progress.listen((step) => onPage?.call(step.$1, step.$2));
    try {
      final read = await methods.invokeMapMethod<String, Object?>('readText', {
        'path': file.path,
        'kind': file.isPdf ? 'pdf' : 'image',
        'withImages': true,
      });
      return _text(read ?? const {});
    } on PlatformException catch (failure) {
      // O lado nativo responde com o código do catálogo. Código que o app
      // não conhece vira "não consegui ler", que é o que a pessoa viu.
      return ReadFailed(ErrorCode.tryParse(failure.code) ?? ErrorCode.capt01);
    } on MissingPluginException {
      // Sem o módulo (o teste, uma plataforma sem ele): o mesmo que
      // `NoReceiptReader` responde, para trocar um pelo outro não mudar o
      // que quem chama recebe.
      return const ReadFailed(ErrorCode.capt02);
    } finally {
      await listening.cancel();
    }
  }

  /// O que o lado nativo devolveu: o texto juntado, que o comprovante lê,
  /// e o de cada página, em linhas pela posição, com o total real, que o
  /// extrato lê (ADR-030). Lado nativo antigo, sem as páginas, ainda serve:
  /// o texto vira a página única.
  static ReadText _text(Map<String, Object?> read) => ReadText(
    read['text'] as String? ?? '',
    images: [
      for (final image in read['images'] as List? ?? const [])
        if (image is Uint8List) image,
    ],
    pages: [
      for (final page in read['pageTexts'] as List? ?? const [])
        if (page is String) page,
    ],
    rows: [
      for (final page in read['pageRows'] as List? ?? const [])
        if (page is String) page,
    ],
    pageCount: read['pageCount'] as int?,
    imagePages: [
      for (final page in read['imagePages'] as List? ?? const [])
        if (page is int) page,
    ],
  );
}
