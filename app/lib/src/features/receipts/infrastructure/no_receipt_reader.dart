import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/receipts/application/read_outcome.dart';
import 'package:cajui/src/features/receipts/application/receipt_reader.dart';
import 'package:cajui/src/features/receipts/application/shared_item.dart';

/// O leitor de onde não há leitura de comprovante: a web (ADR-013). Como a
/// caixa de entrada de lá nunca recebe nada, isto nem chega a ser chamado;
/// existe para a porta ter sempre alguém atrás.
final class NoReceiptReader implements ReceiptReader {
  /// Cria o leitor que não lê.
  const new();

  @override
  Future<ReadOutcome> read(
    SharedFile file, {
    void Function(int page, int of)? onPage,
  }) async => const ReadFailed(ErrorCode.capt02);
}
