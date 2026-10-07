import 'dart:typed_data';

import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// Um comprovante já lido, guardado no aparelho à espera de conferência.
///
/// Guarda o **texto**, e não a proposta: a classificação por regras é barata
/// e sempre dá o mesmo resultado, então refazer ao reabrir sai mais simples —
/// e mais certo, porque usa as regras aprendidas até ali — do que gravar uma
/// proposta que envelhece.
@immutable
final class PendingCapture {
  /// Cria a captura pendente.
  const new({
    required this.id,
    required this.receivedOn,
    required this.text,
    this.filePath,
    this.images = const [],
  });

  /// O identificador da chegada: a chave de idempotência do lançamento.
  final String id;

  /// O dia em que o comprovante chegou.
  final LocalDate receivedOn;

  /// O texto lido, já limpo.
  final String text;

  /// O arquivo original no aparelho; `null` quando o que chegou foi texto.
  final String? filePath;

  /// As imagens para a IA, da leitura de agora (ADR-022). Não ficam
  /// guardadas: quem reabre uma captura guardada reclassifica pelo texto.
  final List<Uint8List> images;
}
