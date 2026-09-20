import 'package:design_system/design_system.dart';
import 'package:gallery/src/pages/screens/capture/capture_kind.dart';

/// Os 17 estados da tela de captura, com o texto real de
/// `docs/spec/sharing-flow.md`.
///
/// O texto mora aqui, e não espalhado pela tela, para que a conferência com
/// a especificação seja uma leitura de cima para baixo.
enum CaptureState {
  /// O arquivo acabou de chegar pelo compartilhamento.
  receiving(
    'Recebendo',
    CaptureKind.progress,
    what: 'Guardando o comprovante…',
    actions: [],
  ),

  /// A leitura local está em curso.
  reading(
    'Lendo',
    CaptureKind.progress,
    what: 'Lendo o comprovante no seu aparelho.',
    meaning: 'Página 2 de 4',
    actions: ['Cancelar'],
  ),

  /// As regras já leram valor e data; falta a categoria.
  classifying(
    'Classificando',
    CaptureKind.progress,
    what: 'Identificando o que foi comprado…',
    meaning: 'R\$${BrlFormatter.nbsp}186,40 · 12/09 já identificados',
    actions: ['Preencher à mão'],
  ),

  /// A tela de confirmação, com tudo preenchido.
  confirming('Confirmando', CaptureKind.form),

  /// A confiança ficou média: o app pergunta em vez de chutar.
  asking(
    'Perguntando',
    CaptureKind.question,
    what: 'Fiquei entre estas. O que foi comprado na Drogaria Central?',
    actions: ['Outra coisa'],
  ),

  /// Sem rede: a leitura local preenche o que dá.
  offline(
    'Sem rede',
    CaptureKind.form,
    what: 'Sem conexão agora.',
    meaning:
        'Li o comprovante aqui mesmo e preenchi o que deu; a categoria fica '
        'com você. O lançamento sobe sozinho quando a rede voltar.',
    actions: ['Lançar', 'Conferir depois'],
  ),

  /// A IA não respondeu: valem as regras locais.
  aiDown(
    'IA fora do ar',
    CaptureKind.form,
    code: 'E-AI-01',
    what: 'A classificação automática está fora do ar.',
    meaning: 'Usei as regras locais — confira a categoria antes de lançar.',
    actions: ['Lançar', 'Conferir depois'],
  ),

  /// A leitura não achou texto.
  unreadable(
    'Sem texto legível',
    CaptureKind.notice,
    code: 'E-CAPT-01',
    intent: CajuiNoticeIntent.danger,
    what: 'Não consegui ler este comprovante.',
    meaning:
        'A imagem ficou escura ou pequena demais para o texto aparecer. O '
        'arquivo está guardado.',
    actions: ['Tirar outra foto', 'Digitar os dados'],
  ),

  /// O arquivo não é de um tipo que o app lê.
  invalidFile(
    'Arquivo inválido',
    CaptureKind.notice,
    code: 'E-CAPT-02',
    intent: CajuiNoticeIntent.danger,
    what: 'Este arquivo não é uma imagem, um PDF nem um texto.',
    meaning: 'O Cajui lê JPEG, PNG, WebP, PDF e texto.',
    actions: ['Escolher outro'],
  ),

  /// O arquivo passa do limite de tamanho.
  tooLarge(
    'Arquivo grande demais',
    CaptureKind.notice,
    code: 'E-CAPT-03',
    intent: CajuiNoticeIntent.danger,
    what: 'Este arquivo tem 22 MB e o limite é 15 MB.',
    meaning: 'Um print da tela do comprovante resolve.',
    actions: ['Escolher outro'],
  ),

  /// PDF protegido por senha.
  lockedPdf(
    'PDF com senha',
    CaptureKind.notice,
    code: 'E-CAPT-04',
    intent: CajuiNoticeIntent.danger,
    what: 'Este PDF está protegido por senha.',
    meaning:
        'O Cajui não abre arquivo protegido. Um print da página com o valor '
        'resolve.',
    actions: ['Escolher outro', 'Digitar os dados'],
  ),

  /// O mesmo arquivo já virou lançamento.
  duplicate(
    'Arquivo repetido',
    CaptureKind.notice,
    intent: CajuiNoticeIntent.info,
    what: 'Este comprovante já virou um lançamento em 12/09.',
    meaning: 'Mercado Boa Compra, R\$${BrlFormatter.nbsp}186,40.',
    actions: ['Abrir o lançamento', 'Lançar mesmo assim'],
  ),

  /// Arquivo diferente, mas valor, lugar e dia iguais.
  maybeDuplicate(
    'Parece repetido',
    CaptureKind.notice,
    what:
        'Já existe um lançamento de R\$${BrlFormatter.nbsp}8,50 na Padaria '
        'Central hoje.',
    meaning: 'É outro?',
    actions: ['É outro, lançar', 'É o mesmo, descartar'],
  ),

  /// Vários arquivos compartilhados de uma vez (RN-705).
  manyFiles(
    'Vários arquivos',
    CaptureKind.form,
    overline: '3 comprovantes para conferir · 1 de 3',
  ),

  /// Um extrato com várias movimentações (RN-707).
  statement(
    'Extrato',
    CaptureKind.form,
    overline: 'Movimentação 1 de 12',
    intent: CajuiNoticeIntent.info,
    what: 'Encontrei 12 movimentações neste extrato.',
    meaning: 'Confira uma a uma, ou pule as que não interessam.',
    actions: ['Confirmar', 'Pular'],
  ),

  /// O app de origem não liberou a leitura do arquivo.
  noPermission(
    'Sem permissão de leitura',
    CaptureKind.notice,
    code: 'E-CAPT-05',
    intent: CajuiNoticeIntent.danger,
    what: 'O app de origem não liberou o arquivo.',
    meaning:
        'Tente compartilhar de novo, ou salve o comprovante na galeria e '
        'compartilhe de lá.',
    actions: ['Entendi'],
  ),

  /// Não há espaço no aparelho para guardar o arquivo.
  storageFull(
    'Armazenamento cheio',
    CaptureKind.notice,
    code: 'E-CAPT-06',
    intent: CajuiNoticeIntent.danger,
    what: 'Não há espaço no aparelho para guardar o comprovante.',
    meaning:
        'Faltam cerca de 4 MB. Nada foi perdido: ele continua no app de '
        'origem.',
    actions: ['Abrir armazenamento', 'Digitar os dados'],
  );

  new(
    this.label,
    this.kind, {
    this.code,
    this.overline,
    this.intent = CajuiNoticeIntent.attention,
    this.what,
    this.meaning,
    this.actions = const ['Lançar', 'Conferir depois', 'Descartar'],
  });

  /// O nome do estado no seletor.
  final String label;

  /// A forma que a tela toma.
  final CaptureKind kind;

  /// O código do catálogo de erros, quando o estado é um erro.
  final String? code;

  /// A linha miúda acima do título.
  final String? overline;

  /// A intenção do aviso, quando há aviso.
  final CajuiNoticeIntent intent;

  /// O que aconteceu.
  final String? what;

  /// O que isso significa, ou o que já se sabe.
  final String? meaning;

  /// As ações, da principal para a menos importante.
  final List<String> actions;

  /// A nota da página: de onde o estado vem.
  String get note {
    const source = 'Texto de docs/spec/sharing-flow.md';
    return code == null ? source : '$code · $source';
  }
}
