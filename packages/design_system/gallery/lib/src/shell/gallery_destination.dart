import 'package:gallery/src/shell/gallery_group.dart';

/// Cada página da gallery.
///
/// É um enum, e não uma lista, para que o `switch` que monta a página seja
/// exaustivo: acrescentar um destino sem acrescentar a página não compila.
/// A ordem dos valores é a ordem do menu e do "anterior · próxima".
enum GalleryDestination {
  /// O que é o Cajui, por onde começar e os números.
  overview('Visão geral', GalleryGroup.start, 'visao-geral'),

  /// Todas as telas do app, em todos os estados, lado a lado.
  screenStates('Estados das telas', GalleryGroup.app, 'estados-das-telas'),

  /// O Início, em todos os estados.
  home('Início', GalleryGroup.app, 'inicio'),

  /// A conversa com a Juju, o extrato conferido com ela e as falhas da IA.
  assistant('Juju, a assistente', GalleryGroup.app, 'juju'),

  /// O comprovante que vira lançamento, nos estados do compartilhamento.
  capture('Comprovante', GalleryGroup.app, 'comprovante'),

  /// A fatura do cartão: visão calculada, nunca despesa.
  statement('Fatura do cartão', GalleryGroup.app, 'fatura'),

  /// O fechamento do mês, com sobra e com falta.
  closing('Fechamento do mês', GalleryGroup.app, 'fechamento'),

  /// As dívidas e o marco de quitação.
  debts('Dívidas', GalleryGroup.app, 'dividas'),

  /// O widget da tela inicial, de vidro, e o app que nasce dele.
  homeWidget('Widget da tela inicial', GalleryGroup.app, 'widget'),

  /// A rolagem que curva nas bordas como a face de um tambor.
  depthScroll('Rolagem em profundidade', GalleryGroup.motion, 'rolagem-3d'),

  /// Os números do mês num carrossel 3D.
  coverFlow('Carrossel 3D', GalleryGroup.motion, 'carrossel-3d'),

  /// O travelling de câmera ao abrir a tela.
  cinematic(
    'Entrada cinematográfica',
    GalleryGroup.motion,
    'entrada-cinematografica',
  ),

  /// Os cartões que saem do maço e se empilham ao rolar.
  wallet('Pilha de cartões', GalleryGroup.motion, 'pilha-de-cartoes'),

  /// A câmera que avança para a tela nova e orbita entre as abas.
  camera('Troca de tela', GalleryGroup.motion, 'troca-de-tela'),

  /// Cartão em 3D, número que rola e voa, semente e folha, brilho, mês a
  /// mês e resposta palavra por palavra.
  alive('Microinterações', GalleryGroup.motion, 'microinteracoes'),

  /// A mesa de movimento: curvas, durações e os três níveis.
  motionDesk('Mesa de movimento', GalleryGroup.motion, 'mesa-de-movimento'),

  /// A mesa de som: ouvir e aprovar cada som.
  soundDesk('Mesa de som', GalleryGroup.motion, 'mesa-de-som'),

  /// Botão, botão de ícone, chip, chave e barra de navegação.
  action('Botões e controles', GalleryGroup.components, 'botoes'),

  /// Valor, cartão, linha de lista, medidor e confiança.
  content('Valores e cartões', GalleryGroup.components, 'valores-e-cartoes'),

  /// Campo de texto, de valor e de escolha.
  fields('Campos', GalleryGroup.components, 'campos'),

  /// Aviso, vazio, esqueleto, carregando e ícone-herói.
  states(
    'Aviso, vazio e carregando',
    GalleryGroup.components,
    'aviso-vazio-e-carregando',
  ),

  /// A fala comum e a fala que pede resposta, com botões ou opções.
  conversation('Conversa', GalleryGroup.components, 'conversa'),

  /// Os papéis de cor, no tema em vigor.
  colors('Cores', GalleryGroup.foundations, 'cores'),

  /// A falta do mês em barro e em vermelho, lado a lado.
  shortfall('Cor da falta', GalleryGroup.foundations, 'cor-da-falta'),

  /// A tabela de contraste, calculada ao vivo.
  contrast('Contraste', GalleryGroup.foundations, 'contraste'),

  /// A escala tipográfica.
  typography('Tipografia', GalleryGroup.foundations, 'tipografia'),

  /// Espaçamento, raio e elevação.
  layout('Espaço, raio e sombra', GalleryGroup.foundations, 'espaco'),

  /// Todos os ícones, percorrendo o enum.
  icons('Ícones', GalleryGroup.foundations, 'icones');

  new(this.title, this.group, this.slug);

  /// O nome da página no menu, igual ao título dela.
  final String title;

  /// O grupo do menu a que a página pertence.
  final GalleryGroup group;

  /// O pedaço do endereço: `/gallery/#/widget`. Curto, sem acento e fixo —
  /// é o que vai no README e no currículo.
  final String slug;

  /// As páginas de um [group], na ordem do menu.
  static Iterable<GalleryDestination> inGroup(GalleryGroup group) =>
      values.where((destination) => destination.group == group);

  /// A página do endereço [slug], se houver.
  static GalleryDestination? bySlug(String slug) {
    for (final destination in values) {
      if (destination.slug == slug) return destination;
    }
    return null;
  }
}
