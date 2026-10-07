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

  /// Se dá para fotografar por aqui. Falso na web, que é só consulta.
  bool get canPhotograph;

  /// Abre a câmera do aparelho para fotografar um comprovante de papel
  /// (ADR-017). Devolve `false` quando não há câmera — aí o botão não existe.
  ///
  /// A foto não volta por aqui: ela entra na mesma fila do compartilhamento,
  /// e chega por [arrivals]. Fotografar e compartilhar são o mesmo caminho.
  Future<bool> takePhoto();

  /// Se dá para escolher arquivos do aparelho por aqui. Falso na web.
  bool get canPickFiles;

  /// Abre o seletor do aparelho para escolher fotos, prints e PDFs. Como na
  /// câmera, o que for escolhido não volta por aqui: chega por [arrivals].
  /// Devolve `false` quando não há seletor.
  Future<bool> pickFiles();

  /// Apaga o arquivo local de uma captura descartada (RN-723).
  Future<void> discard(SharedFile file);
}
