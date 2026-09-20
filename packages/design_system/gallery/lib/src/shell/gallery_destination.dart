import 'package:gallery/src/shell/gallery_group.dart';

/// Cada página da gallery.
///
/// É um enum, e não uma lista, para que o `switch` que monta a página seja
/// exaustivo: acrescentar um destino sem acrescentar a página não compila.
enum GalleryDestination {
  /// Os papéis de cor, no tema em vigor.
  colors('Cores', GalleryGroup.foundations),

  /// A tabela de contraste, calculada ao vivo.
  contrast('Contraste', GalleryGroup.foundations),

  /// A escala tipográfica.
  typography('Tipografia', GalleryGroup.foundations),

  /// Espaçamento, raio e elevação.
  layout('Espaço, raio e sombra', GalleryGroup.foundations),

  /// Botão, botão de ícone, chip e chave.
  action('Ação', GalleryGroup.components),

  /// Valor, cartão, linha de lista, medidor e confiança.
  content('Conteúdo', GalleryGroup.components),

  /// Campo de texto, de valor e de escolha.
  fields('Campos', GalleryGroup.components),

  /// Aviso, vazio, esqueleto, carregando e ícone-herói.
  states('Estados', GalleryGroup.components),

  /// O painel, em todos os estados.
  dashboard('Painel', GalleryGroup.screens),

  /// A confirmação de captura, nos 17 estados do compartilhamento.
  capture('Captura', GalleryGroup.screens),

  /// A fatura do cartão: visão calculada, nunca despesa.
  statement('Fatura', GalleryGroup.screens),

  /// O fechamento do mês, com sobra e com falta.
  closing('Fechamento', GalleryGroup.screens),

  /// As dívidas e o marco de quitação.
  debts('Dívidas', GalleryGroup.screens),

  /// A conversa com o assistente e as falhas da IA.
  assistant('Assistente', GalleryGroup.screens);

  new(this.title, this.group);

  /// O nome da página no menu.
  final String title;

  /// O grupo do menu a que a página pertence.
  final GalleryGroup group;

  /// As páginas de um [group], na ordem do menu.
  static Iterable<GalleryDestination> inGroup(GalleryGroup group) =>
      values.where((destination) => destination.group == group);
}
