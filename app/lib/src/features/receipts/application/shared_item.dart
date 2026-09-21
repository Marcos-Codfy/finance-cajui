import 'package:api_contract/api_contract.dart';
import 'package:meta/meta.dart';

/// O que outro app compartilhou com o Cajui, já dentro da área privada.
///
/// Quando chega aqui, o lado nativo já conferiu tipo, tamanho e espaço, e já
/// trocou o nome do arquivo por um identificador próprio (ADR-006).
@immutable
sealed class SharedItem {
  const new({required this.id});

  /// O identificador gerado na chegada. É também a chave de idempotência do
  /// lançamento que nascer desta captura (RN-781).
  final String id;
}

/// Uma imagem ou um PDF, copiado para o arquivo local [path].
final class SharedFile extends SharedItem {
  /// Cria o item de arquivo.
  const new({required super.id, required this.path, required this.isPdf});

  /// Onde o original está guardado no aparelho.
  final String path;

  /// Se é PDF. O resto é imagem.
  final bool isPdf;
}

/// Um texto compartilhado direto — a mensagem de um Pix, por exemplo.
final class SharedText extends SharedItem {
  /// Cria o item de texto.
  const new({required super.id, required this.text});

  /// O texto como veio.
  final String text;
}

/// Um compartilhamento que o lado nativo recusou, com o motivo do catálogo.
final class RejectedShare extends SharedItem {
  /// Cria a recusa de código [code].
  const new({required super.id, required this.code, this.detail = const {}});

  /// Por que foi recusado: `E-CAPT-02`, `03`, `05` ou `06`.
  final ErrorCode code;

  /// Os valores que o texto do erro usa: tamanho, espaço que falta.
  final Map<String, Object?> detail;
}
