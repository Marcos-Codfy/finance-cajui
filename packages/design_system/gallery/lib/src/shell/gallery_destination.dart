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

  /// Todos os ícones, percorrendo o enum.
  icons('Ícones', GalleryGroup.foundations),

  /// Botão, botão de ícone, chip e chave.
  action('Ação', GalleryGroup.components),

  /// Valor, cartão, linha de lista, medidor e confiança.
  content('Conteúdo', GalleryGroup.components),

  /// Campo de texto, de valor e de escolha.
  fields('Campos', GalleryGroup.components),

  /// Aviso, vazio, esqueleto, carregando e ícone-herói.
  states('Estados', GalleryGroup.components),

  /// Cartão em 3D, número que rola e voa, semente e folha, brilho, mês a
  /// mês e resposta palavra por palavra.
  alive('Efeitos vivos', GalleryGroup.components),

  /// A rolagem que curva nas bordas como a face de um tambor.
  depthScroll('Rolagem em profundidade', GalleryGroup.depth),

  /// Os números do mês num carrossel 3D.
  coverFlow('Carrossel 3D', GalleryGroup.depth),

  /// O travelling de câmera ao abrir a tela.
  cinematic('Entrada cinematográfica', GalleryGroup.depth),

  /// Os cartões que saem do maço e se empilham ao rolar.
  wallet('Pilha de carteira', GalleryGroup.depth),

  /// O Início, em todos os estados.
  home('Início', GalleryGroup.screens),

  /// A confirmação de captura, nos 17 estados do compartilhamento.
  capture('Captura', GalleryGroup.screens),

  /// A fatura do cartão: visão calculada, nunca despesa.
  statement('Fatura', GalleryGroup.screens),

  /// O fechamento do mês, com sobra e com falta.
  closing('Fechamento', GalleryGroup.screens),

  /// As dívidas e o marco de quitação.
  debts('Dívidas', GalleryGroup.screens),

  /// A conversa com a Juju, o extrato conferido com ela e as falhas da IA.
  assistant('Juju', GalleryGroup.screens),

  /// A falta do mês em barro e em vermelho, lado a lado.
  shortfall('Falta: barro × vermelho', GalleryGroup.decisions),

  /// A mesa de som: ouvir e aprovar cada som.
  soundDesk('Mesa de som', GalleryGroup.senses),

  /// A mesa de movimento: curvas, durações e os três níveis.
  motionDesk('Mesa de movimento', GalleryGroup.senses);

  new(this.title, this.group);

  /// O nome da página no menu.
  final String title;

  /// O grupo do menu a que a página pertence.
  final GalleryGroup group;

  /// As páginas de um [group], na ordem do menu.
  static Iterable<GalleryDestination> inGroup(GalleryGroup group) =>
      values.where((destination) => destination.group == group);
}
