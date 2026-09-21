import 'package:cajui/src/features/receipts/application/read_outcome.dart';
import 'package:cajui/src/features/receipts/application/shared_item.dart';

/// Lê o texto de um comprovante **no aparelho** (ADR-007). A imagem nunca
/// sai dele: daqui para a frente só existe o texto.
abstract interface class ReceiptReader {
  /// O texto de [file]. [onPage] recebe o progresso real da leitura de um
  /// PDF: a página em leitura e o total.
  Future<ReadOutcome> read(
    SharedFile file, {
    void Function(int page, int of)? onPage,
  });
}
