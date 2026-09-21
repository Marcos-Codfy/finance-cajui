import 'package:cajui/src/features/receipts/application/shared_item.dart';

/// Por onde chegam os comprovantes compartilhados por outros apps.
///
/// É uma porta: no Android, por trás, está o módulo nativo de captura; na
/// web não há compartilhamento, e a caixa fica sempre vazia.
abstract interface class ReceiptInbox {
  /// Avisa que chegou algo. Não traz o item: quem ouve chama [takePending],
  /// e assim abertura a frio e app já aberto seguem o mesmo caminho.
  Stream<void> get arrivals;

  /// Os itens que chegaram desde a última chamada, na ordem recebida.
  Future<List<SharedItem>> takePending();

  /// Apaga o arquivo local de uma captura descartada (RN-723).
  Future<void> discard(SharedFile file);
}
