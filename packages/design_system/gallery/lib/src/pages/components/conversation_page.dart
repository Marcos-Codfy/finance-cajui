import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/assistant/statement_sample.dart';
import 'package:gallery/src/pages/screens/home/home_numbers.dart';
import 'package:gallery/src/shell/gallery_page.dart';
import 'package:gallery/src/shell/gallery_section.dart';
import 'package:gallery/src/shell/gallery_specimen.dart';
import 'package:gallery/src/shell/gallery_specimens.dart';

/// A conversa com a Juju, peça por peça: a fala comum (`CajuiChatBubble`) e
/// a fala que pede resposta (`CajuiChatPrompt`), com botões ou opções.
class ConversationPage extends StatefulWidget {
  /// Cria a página.
  const new({super.key});

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  static const double _width = 340;
  static const String _juju = 'Juju';

  /// A resposta escolhida na pergunta ao vivo.
  String? _answer;

  void _nothing() {}

  static String _brl(int cents) => BrlFormatter.format(cents);

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Conversa',
      lead:
          'As falas da conversa com a Juju. Quem fala se distingue pelo lado, '
          'pela cor e pelo nome que o leitor de tela diz antes da fala — '
          'nunca só pela cor.',
      sections: [_bubbles(), _prompts(), _answers()],
    );
  }

  Widget _bubbles() => GallerySection(
    title: 'Fala comum',
    description:
        'O balão é lido inteiro, uma vez, com o nome de quem fala antes. Na '
        'espera, três pontos que respiram, e o leitor de tela ouve "Juju '
        'está respondendo".',
    child: GallerySpecimens(
      children: [
        _specimen(
          'Da Juju',
          CajuiChatBubble(
            'Sobram ${_brl(HomeNumbers.leftover)} neste mês.',
            speaker: _juju,
          ),
        ),
        _specimen(
          'De quem usa',
          const CajuiChatBubble('Quanto sobra neste mês?', fromUser: true),
        ),
        _specimen(
          'Respondendo',
          const CajuiChatBubble('', thinking: true, speaker: _juju),
        ),
      ],
    ),
  );

  Widget _prompts() => GallerySection(
    title: 'Fala que pede resposta',
    description:
        'Só o texto e a lista ficam no balão. Os botões e as opções ficam '
        'fora dele, cada um com o seu nome: a fala comum esconde tudo o que '
        'tem dentro, e quem usa leitor de tela não conseguiria responder.',
    child: GallerySpecimens(
      children: [
        _specimen('Com botões', _done()),
        _specimen('Com lista e botões', _transport()),
        _specimen('Com lista cortada', _installments()),
        _specimen(
          'Já respondida',
          CajuiChatPrompt(StatementSample.market, speaker: _juju),
        ),
      ],
    ),
  );

  Widget _specimen(String state, Widget child) =>
      GallerySpecimen(state: state, width: _width, child: child);

  CajuiPromptAction _action(String label, {bool primary = false}) =>
      (label: label, onPressed: _nothing, primary: primary);

  /// As linhas da lista curta, com o valor já escrito.
  static List<CajuiPromptRow> _rows(List<(String, int)> lines) => [
    for (final (label, cents) in lines) (label: label, value: _brl(cents)),
  ];

  Widget _done() => CajuiChatPrompt(
    StatementSample.done(58),
    speaker: _juju,
    actions: [_action('Desfazer')],
  );

  /// Um bloco com as linhas abertas: o nome encolhe com reticências, o
  /// valor nunca — é ele que se confere.
  Widget _transport() => CajuiChatPrompt(
    'Transporte — 5 compras, ${_brl(9640)}: Uber, 99 e Posto Ipê. Confere?',
    speaker: _juju,
    rows: _rows(const [
      ('02/10 · Uber', 1890),
      ('06/10 · 99', 1240),
      ('11/10 · Posto Ipê', 4000),
      ('17/10 · Uber', 1460),
      ('24/10 · 99', 1050),
    ]),
    actions: [_action('Confere', primary: true), _action('Corrigir')],
  );

  /// RN-1111: as parcelas de compras de outros meses, numa pergunta só.
  Widget _installments() => CajuiChatPrompt(
    '8 parcelas de compras de outros meses, ${_brl(64000)} — lanço como '
    'gasto deste mês?',
    speaker: _juju,
    rows: _rows(const [
      ('Magazine Cerrado · 2 de 10', 12000),
      ('Ótica Visão · 4 de 6', 8500),
      ('Loja Ipê · 3 de 5', 6490),
    ]),
    more: 'e mais 5',
    actions: [_action('Lançar', primary: true), _action('Não lançar')],
  );

  Widget _answers() {
    final answer = _answer;
    return GallerySection(
      title: 'Opções, ao vivo',
      description:
          'Uma escolha só, em chips. Escolhida, a pergunta perde as opções, '
          'e a resposta vira uma fala de quem usa.',
      child: SizedBox(
        width: _width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CajuiChatPrompt(
              StatementSample.kindQuestion,
              speaker: _juju,
              options: answer == null ? StatementSample.kinds : const [],
              onOption: (choice) => setState(() => _answer = choice),
            ),
            if (answer != null) ..._reply(answer),
          ],
        ),
      ),
    );
  }

  List<Widget> _reply(String answer) => [
    CajuiChatBubble(answer, fromUser: true),
    Align(
      alignment: Alignment.centerLeft,
      child: CajuiButton(
        label: 'Perguntar de novo',
        size: CajuiButtonSize.compact,
        variant: CajuiButtonVariant.ghost,
        onPressed: () => setState(() => _answer = null),
      ),
    ),
  ];
}
