import 'package:cajui/src/features/receipts/application/read_outcome.dart';
import 'package:cajui/src/features/receipts/application/receipt_reader.dart';
import 'package:cajui/src/features/receipts/application/shared_item.dart';

/// Um leitor que devolve o que o teste combinou para cada arquivo.
class FakeReader implements ReceiptReader {
  /// Cria o leitor com o resultado de cada caminho de arquivo.
  new(this.outcomes);

  /// Caminho do arquivo → o que a leitura devolve.
  final Map<String, ReadOutcome> outcomes;

  @override
  Future<ReadOutcome> read(
    SharedFile file, {
    void Function(int page, int of)? onPage,
  }) async {
    if (file.isPdf) onPage?.call(1, 2);
    return outcomes[file.path] ?? const ReadText('');
  }
}
