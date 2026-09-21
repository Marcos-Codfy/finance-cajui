import 'package:cajui/src/features/receipts/application/receipt_inbox.dart';
import 'package:cajui/src/features/receipts/application/shared_item.dart';

/// A caixa de entrada de onde não existe compartilhamento: a web, que é só
/// modo consulta (ADR-013). Nunca chega nada.
final class NoReceiptInbox implements ReceiptInbox {
  /// Cria a caixa vazia.
  const new();

  @override
  Stream<void> get arrivals => const Stream.empty();

  @override
  Future<List<SharedItem>> takePending() async => const [];

  @override
  Future<void> discard(SharedFile file) async {}
}
